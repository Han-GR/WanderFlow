import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    @Binding var editingExpense: Expense?
    @State private var expenseToDelete: Expense?
    
    private var sortedExpenses: [Expense] {
        trip.expenses.sorted { (lhs, rhs) in
            let l = lhs.occurredAt ?? lhs.createdAt
            let r = rhs.occurredAt ?? rhs.createdAt
            return l > r
        }
    }
    
    private var currencyTotals: [(String, Double)] {
        let totals = trip.expenses.reduce(into: [String: Double]()) { dict, exp in
            dict[exp.currency, default: 0] += exp.amount
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        List {
            if !currencyTotals.isEmpty {
                Section("总支出") {
                    ForEach(currencyTotals, id: \.0) { currency, amount in
                        HStack {
                            Text(currency)
                            Spacer()
                            Text(amount, format: .currency(code: currency))
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            
            Section("明细") {
                ForEach(sortedExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.note.isEmpty ? expense.category : expense.note)
                                .font(AppTypography.sectionTitle)
                            Text(expense.note.isEmpty ? "" : expense.category)
                                .font(AppTypography.captionEmphasis)
                                .foregroundColor(.secondary)
                            Text(expense.occurredAt ?? expense.createdAt, format: .dateTime.month().day())
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(expense.amount, format: .currency(code: expense.currency))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .listCard()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingExpense = expense
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            expenseToDelete = expense
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            
            if trip.expenses.isEmpty {
                Section {
                    ContentUnavailableView("还没有支出", systemImage: "creditcard", description: Text("点击右上角 + 记录第一笔开销"))
                }
            }
        }
        .cuteListStyle()
        .alert("删除这笔支出？", isPresented: Binding(get: { expenseToDelete != nil }, set: { if !$0 { expenseToDelete = nil } })) {
            Button("删除", role: .destructive) {
                if let expenseToDelete {
                    modelContext.delete(expenseToDelete)
                    if let idx = trip.expenses.firstIndex(where: { $0.id == expenseToDelete.id }) {
                        trip.expenses.remove(at: idx)
                    }
                    try? modelContext.save()
                }
                expenseToDelete = nil
            }
            Button("取消", role: .cancel) {
                expenseToDelete = nil
            }
        }
    }
}
