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
        case itinerary = "行程"
        case expenses = "支出"
        case summary = "汇总"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TripDetailHeader(trip: trip, onEditDefaultCity: {
                isShowingDefaultCityPicker = true
            })
            Picker("视图切换", selection: $selection) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
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
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        isShowingAddMenu = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    Button {
                        isShowingMoreMenu = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("删除这趟旅行？", isPresented: $isConfirmingDelete) {
            Button("删除旅行", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingAddMenu) {
            TripDetailAddMenuSheet(
                onAddItinerary: {
                    editingItem = nil
                    isShowingAddItinerary = true
                },
                onAddExpense: {
                    quickExpenseNote = nil
                    quickExpenseOccurredAt = nil
                    quickExpenseCategory = "其他"
                    isShowingAddExpense = true
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingMoreMenu) {
            TripDetailMoreMenuSheet(
                onEditTrip: { isShowingTripEditor = true },
                onDeleteTrip: { isConfirmingDelete = true }
            )
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
                            Button("清除") {
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

private struct TripDetailAddMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onAddItinerary: () -> Void
    var onAddExpense: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 10) {
                TripDetailMenuRow(title: "行程", systemImage: "mappin.and.ellipse") {
                    dismiss()
                    DispatchQueue.main.async { onAddItinerary() }
                }
                TripDetailMenuRow(title: "支出", systemImage: "creditcard") {
                    dismiss()
                    DispatchQueue.main.async { onAddExpense() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct TripDetailMoreMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onEditTrip: () -> Void
    var onDeleteTrip: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 10) {
                TripDetailMenuRow(title: "编辑旅行", systemImage: "pencil") {
                    dismiss()
                    DispatchQueue.main.async { onEditTrip() }
                }
                TripDetailMenuRow(title: "删除旅行",systemImage: "trash", isDestructive: true) {
                    dismiss()
                    DispatchQueue.main.async { onDeleteTrip() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

 
