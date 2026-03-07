import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var currency: String = "CNY"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("支出") {
                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("备注", text: $note)
                    Picker("币种", selection: $currency) {
                        Text("CNY").tag("CNY")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("JPY").tag("JPY")
                    }
                }
            }
            .navigationTitle("记一笔")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let amount = Double(amountText) else { return }
                        let exp = Expense(amount: amount, currency: currency, note: note)
                        modelContext.insert(exp)
                        trip.expenses.append(exp)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
