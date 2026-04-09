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
                Section("expenses.total.section") {
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
            
            Section("expenses.list.section") {
                ForEach(sortedExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.note.isEmpty ? ExpenseCategoryLocalization.name(for: expense.category) : expense.note)
                                .font(AppTypography.sectionTitle)
                            Text(expense.note.isEmpty ? "" : ExpenseCategoryLocalization.name(for: expense.category))
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
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                }
            }
            
            if trip.expenses.isEmpty {
                Section {
                    ContentUnavailableView("expenses.empty.title", systemImage: "creditcard", description: Text("expenses.empty.subtitle"))
                }
            }
        }
        .cuteListStyle()
        .alert("expenses.alert.delete.title", isPresented: Binding(get: { expenseToDelete != nil }, set: { if !$0 { expenseToDelete = nil } })) {
            Button("common.delete", role: .destructive) {
                if let expenseToDelete {
                    modelContext.delete(expenseToDelete)
                    if let idx = trip.expenses.firstIndex(where: { $0.id == expenseToDelete.id }) {
                        trip.expenses.remove(at: idx)
                    }
                    try? modelContext.save()
                }
                expenseToDelete = nil
            }
            Button("common.cancel", role: .cancel) {
                expenseToDelete = nil
            }
        }
    }
}
