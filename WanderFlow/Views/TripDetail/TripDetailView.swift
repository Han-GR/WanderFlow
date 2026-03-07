import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var selection: DetailTab = .itinerary
    @State private var isShowingTripEditor: Bool = false
    @State private var isShowingAddItinerary: Bool = false
    @State private var isShowingAddExpense: Bool = false
    @State private var isConfirmingDelete: Bool = false
    @State private var editingItem: ItineraryItem?
    
    enum DetailTab: String, CaseIterable {
        case itinerary = "行程"
        case expenses = "支出"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("视图切换", selection: $selection) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            if selection == .itinerary {
                ItineraryListView(trip: trip, editingItem: $editingItem)
            } else {
                ExpenseListView(trip: trip)
            }
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        if selection == .itinerary {
                            editingItem = nil
                            isShowingAddItinerary = true
                        } else {
                            isShowingAddExpense = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    Menu {
                        Button("编辑旅行") { isShowingTripEditor = true }
                        Button("删除旅行", role: .destructive) { isConfirmingDelete = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("删除这趟旅行？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("删除旅行", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingTripEditor) {
            TripEditorSheet(trip: trip)
        }
        .sheet(isPresented: $isShowingAddItinerary) {
            AddItineraryItemSheet(trip: trip, itemToEdit: editingItem)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingAddExpense) {
            AddExpenseSheet(trip: trip)
                .presentationDetents([.medium])
        }
        // 当 editingItem 变化时自动触发 Sheet
        .onChange(of: editingItem) { _, newItem in
            if newItem != nil {
                isShowingAddItinerary = true
            }
        }
    }
}
