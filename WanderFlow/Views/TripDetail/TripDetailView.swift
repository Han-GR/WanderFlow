import SwiftUI
import SwiftData
import CoreLocation

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var selection: DetailTab = .itinerary
    @State private var isShowingAddMenu: Bool = false
    @State private var isShowingMoreMenu: Bool = false
    @State private var isShowingTripEditor: Bool = false
    @State private var isShowingAddItinerary: Bool = false
    @State private var isShowingAddExpense: Bool = false
    @State private var isShowingDefaultCityPicker: Bool = false
    @State private var isConfirmingDelete: Bool = false
    @State private var editingItem: ItineraryItem?
    @State private var editingExpense: Expense?
    @State private var quickExpenseNote: String?
    @State private var quickExpenseCategory: String?
    @State private var quickExpenseOccurredAt: Date?
    
    
    enum DetailTab: String, CaseIterable {
        case itinerary
        case expenses
        case summary
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .itinerary: return "tripDetail.tabs.itinerary"
            case .expenses: return "tripDetail.tabs.expenses"
            case .summary: return "tripDetail.tabs.summary"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TripDetailHeader(trip: trip, onEditDefaultCity: {
                isShowingDefaultCityPicker = true
            })
            Picker("tripDetail.picker.viewSwitch", selection: $selection) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.titleKey).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .background(CuteTheme.background)
            
            if selection == .itinerary {
                TimelineView(trip: trip, editingItineraryItem: $editingItem, onQuickAddExpense: { item in
                    isShowingAddExpense = true
                    quickExpenseNote = item.title
                    quickExpenseOccurredAt = item.date
                    quickExpenseCategory = "餐饮"
                })
            } else if selection == .expenses {
                ExpenseListView(trip: trip, editingExpense: $editingExpense)
            } else {
                TripSummaryView(trip: trip)
            }
        }
        .background(CuteTheme.background)
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingAddMenu = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(trip.resolvedStyle.accent)
                Button {
                    isShowingMoreMenu = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(trip.resolvedStyle.accent)
            }
        }
        .alert("tripDetail.alert.deleteTrip.title", isPresented: $isConfirmingDelete) {
            Button("tripDetail.alert.deleteTrip.confirm", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("common.cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingAddMenu) {
            CardMenuSheet(items: [
                CardMenuItem(title: NSLocalizedString("tripDetail.menu.add.itinerary", comment: ""), systemImage: "mappin.and.ellipse", isDestructive: false) {
                    editingItem = nil
                    isShowingAddItinerary = true
                },
                CardMenuItem(title: NSLocalizedString("tripDetail.menu.add.expense", comment: ""), systemImage: "creditcard", isDestructive: false) {
                    quickExpenseNote = nil
                    quickExpenseOccurredAt = nil
                    quickExpenseCategory = "其他"
                    isShowingAddExpense = true
                }
            ], accent: trip.resolvedStyle.accent, iconBackground: trip.resolvedStyle.gradient)
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMoreMenu) {
            CardMenuSheet(items: [
                CardMenuItem(title: NSLocalizedString("tripDetail.menu.more.editTrip", comment: ""), systemImage: "pencil", isDestructive: false) {
                    isShowingTripEditor = true
                },
                CardMenuItem(title: NSLocalizedString("tripDetail.menu.more.deleteTrip", comment: ""), systemImage: "trash", isDestructive: true) {
                    isConfirmingDelete = true
                }
            ], accent: trip.resolvedStyle.accent, iconBackground: trip.resolvedStyle.gradient)
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingTripEditor) { TripEditorSheet(trip: trip) }
        .sheet(isPresented: $isShowingDefaultCityPicker) {
            NavigationStack {
                CityPickerView { name, coord in
                    trip.defaultCityName = name
                    trip.defaultCityLatitude = coord.latitude
                    trip.defaultCityLongitude = coord.longitude
                    try? modelContext.save()
                }
                .toolbar {
                    if trip.defaultCityName != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("common.clear") {
                                trip.defaultCityName = nil
                                trip.defaultCityLatitude = nil
                                trip.defaultCityLongitude = nil
                                try? modelContext.save()
                                isShowingDefaultCityPicker = false
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddItinerary, onDismiss: {
            editingItem = nil
        }) {
            AddItineraryItemSheet(trip: trip, itemToEdit: editingItem)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingAddExpense, onDismiss: {
            editingExpense = nil
        }) {
            AddExpenseSheet(trip: trip, expenseToEdit: editingExpense, defaultNote: quickExpenseNote, defaultCategory: quickExpenseCategory, defaultOccurredAt: quickExpenseOccurredAt)
                .presentationDetents([.medium])
        }
        // 当 editingItem 变化时自动触发 Sheet
        .onChange(of: editingItem) { _, newItem in
            if newItem != nil {
                isShowingAddItinerary = true
            }
        }
        .onChange(of: editingExpense) { _, newValue in
            if newValue != nil {
                quickExpenseNote = nil
                quickExpenseOccurredAt = nil
                quickExpenseCategory = nil
                isShowingAddExpense = true
            }
        }
    }
}
 
