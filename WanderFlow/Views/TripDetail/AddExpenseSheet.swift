import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.defaultCurrencyCodeKey) private var defaultCurrencyCode: String = AppSettings.resolvedDefaultCurrencyCode()
    
    var trip: Trip
    var expenseToEdit: Expense?
    var defaultNote: String?
    var defaultCategory: String?
    var defaultOccurredAt: Date?
    
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var currency: String = AppSettings.resolvedDefaultCurrencyCode()
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
            _currency = State(initialValue: AppSettings.resolvedDefaultCurrencyCode())
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
                Section("addExpense.section.expense") {
                    TextField("addExpense.field.amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .tunedNumericInput()
                    Picker("addExpense.field.category", selection: $category) {
                        Text("expense.category.food").tag("餐饮")
                        Text("expense.category.stay").tag("住宿")
                        Text("expense.category.transport").tag("交通")
                        Text("expense.category.ticket").tag("门票")
                        Text("expense.category.shopping").tag("购物")
                        Text("expense.category.other").tag("其他")
                    }
                    .tint(trip.resolvedStyle.accent)
                    TextField("addExpense.field.note", text: $note)
                        .tunedTextInput()
                    NavigationLink {
                        CurrencyPickerView(selectedCurrencyCode: $currency)
                    } label: {
                        HStack {
                            Text("addExpense.field.currency")
                            Spacer()
                            if currency == defaultCurrencyCode {
                                Text("common.default")
                                    .foregroundColor(.secondary)
                            }
                            Text(currency)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("addExpense.section.time") {
                    Toggle("addExpense.toggle.hasTime", isOn: $hasTime).tint(trip.resolvedStyle.accent)
                    if hasTime {
                        DatePicker("addExpense.field.occurredAt", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                    } else {
                        Text("addExpense.noTime.hint")
                            .foregroundColor(.secondary)
                            .font(AppTypography.caption)
                    }
                }
                
                if category == "住宿" {
                    Section("addExpense.section.stay") {
                        DatePicker("addExpense.field.stayStart", selection: $stayStartDate, displayedComponents: .date)
                        Stepper(L10n.format("addExpense.field.nights", nights), value: $nights, in: 1...60)
                    }
                }
            }
            .navigationTitle(expenseToEdit == nil ? NSLocalizedString("addExpense.title.add", comment: "") : NSLocalizedString("addExpense.title.edit", comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .tint(trip.resolvedStyle.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
                    .tint(trip.resolvedStyle.accent)
                }
            }
        }
    }
}
