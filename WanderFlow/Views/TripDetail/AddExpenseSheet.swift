import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    var expenseToEdit: Expense?
    var defaultNote: String?
    var defaultCategory: String?
    var defaultOccurredAt: Date?
    
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var currency: String = "CNY"
    @State private var category: String = "其他"
    @State private var hasTime: Bool = true
    @State private var occurredAt: Date = .init()
    
    @State private var stayStartDate: Date = .init()
    @State private var nights: Int = 1
    
    init(trip: Trip, expenseToEdit: Expense? = nil, defaultNote: String? = nil, defaultCategory: String? = nil, defaultOccurredAt: Date? = nil) {
        self.trip = trip
        self.expenseToEdit = expenseToEdit
        self.defaultNote = defaultNote
        self.defaultCategory = defaultCategory
        self.defaultOccurredAt = defaultOccurredAt
        
        if let exp = expenseToEdit {
            _amountText = State(initialValue: String(format: "%.0f", exp.amount))
            _note = State(initialValue: exp.note)
            _currency = State(initialValue: exp.currency)
            _category = State(initialValue: exp.category)
            if let t = exp.occurredAt {
                _hasTime = State(initialValue: true)
                _occurredAt = State(initialValue: t)
            } else {
                _hasTime = State(initialValue: false)
                _occurredAt = State(initialValue: Date())
            }
            if let start = exp.stayStartDate {
                _stayStartDate = State(initialValue: start)
            }
            if let n = exp.nights, n > 0 {
                _nights = State(initialValue: n)
            }
        } else {
            if let dn = defaultNote {
                _note = State(initialValue: dn)
            }
            if let dc = defaultCategory {
                _category = State(initialValue: dc)
            }
            if let dt = defaultOccurredAt {
                _occurredAt = State(initialValue: dt)
                _hasTime = State(initialValue: true)
            } else {
                _hasTime = State(initialValue: false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("支出") {
                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("类别", selection: $category) {
                        Text("机票").tag("机票")
                        Text("餐饮").tag("餐饮")
                        Text("住宿").tag("住宿")
                        Text("交通").tag("交通")
                        Text("门票").tag("门票")
                        Text("其他").tag("其他")
                    }
                    TextField("备注", text: $note)
                    Picker("币种", selection: $currency) {
                        Text("CNY").tag("CNY")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("JPY").tag("JPY")
                    }
                }
                
                Section("时间") {
                    Toggle("指定时间", isOn: $hasTime)
                    if hasTime {
                        DatePicker("发生时间", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        Text("未指定时间的支出会显示为“全天”")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                
                if category == "住宿" {
                    Section("住宿") {
                        DatePicker("入住日期", selection: $stayStartDate, displayedComponents: .date)
                        Stepper("晚数 \(nights)", value: $nights, in: 1...60)
                    }
                }
            }
            .navigationTitle(expenseToEdit == nil ? "记一笔" : "编辑支出")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amount = Double(amountText) else { return }
                        
                        let occurred: Date? = hasTime ? occurredAt : nil
                        let stayStart: Date? = category == "住宿" ? Calendar.current.startOfDay(for: stayStartDate) : nil
                        let stayNights: Int? = category == "住宿" ? nights : nil
                        
                        if let exp = expenseToEdit {
                            exp.amount = amount
                            exp.currency = currency
                            exp.note = note
                            exp.category = category
                            exp.occurredAt = occurred
                            exp.stayStartDate = stayStart
                            exp.nights = stayNights
                        } else {
                            let exp = Expense(
                                amount: amount,
                                currency: currency,
                                note: note,
                                category: category,
                                occurredAt: occurred,
                                stayStartDate: stayStart,
                                nights: stayNights
                            )
                            modelContext.insert(exp)
                            trip.expenses.append(exp)
                        }
                        
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
