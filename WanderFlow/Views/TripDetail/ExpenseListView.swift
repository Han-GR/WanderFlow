import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    private var sortedExpenses: [Expense] {
        trip.expenses.sorted { $0.createdAt > $1.createdAt }
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
                    }
                }
            }
            
            Section("明细") {
                ForEach(sortedExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.note.isEmpty ? "支出" : expense.note)
                                .font(.headline)
                            Text(expense.createdAt, format: .dateTime.month().day())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(expense.amount, format: .currency(code: expense.currency))
                            .foregroundColor(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(expense)
                            if let idx = trip.expenses.firstIndex(where: { $0.id == expense.id }) {
                                trip.expenses.remove(at: idx)
                            }
                            try? modelContext.save()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            
            if trip.expenses.isEmpty {
                Section {
                    ContentUnavailableView("还没有支出", systemImage: "creditcard", description: Text("点击底部按钮记录第一笔开销"))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
