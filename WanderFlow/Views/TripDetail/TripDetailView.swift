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
    @State private var isShowingPasteImport: Bool = false
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
            TripDetailHeader(trip: trip)
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
                TimelineView(trip: trip, editingItineraryItem: $editingItem, editingExpense: $editingExpense, onQuickAddExpense: { item in
                    editingExpense = nil
                    isShowingAddExpense = true
                    quickExpenseNote = item.title
                    quickExpenseOccurredAt = item.date
                    quickExpenseCategory = "餐饮"
                }, showExpenses: false)
            } else if selection == .expenses {
                ExpenseListView(trip: trip)
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
                    Menu {
                        Button("添加行程") {
                            editingItem = nil
                            isShowingAddItinerary = true
                        }
                        Button("记一笔") {
                            editingExpense = nil
                            isShowingAddExpense = true
                        }
                        Button("粘贴解析导入") {
                            isShowingPasteImport = true
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
            AddExpenseSheet(trip: trip, expenseToEdit: editingExpense, defaultNote: quickExpenseNote, defaultCategory: quickExpenseCategory, defaultOccurredAt: quickExpenseOccurredAt)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $isShowingPasteImport) {
            PasteImportSheet(trip: trip)
                .presentationDetents([.large])
        }
        // 当 editingItem 变化时自动触发 Sheet
        .onChange(of: editingItem) { _, newItem in
            if newItem != nil {
                isShowingAddItinerary = true
            }
        }
        .onChange(of: editingExpense) { _, newValue in
            if newValue != nil {
                isShowingAddExpense = true
            }
        }
    }
}
