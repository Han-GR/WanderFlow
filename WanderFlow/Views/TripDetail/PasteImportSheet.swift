import SwiftUI
import SwiftData

struct PasteImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    
    @State private var rawText: String = ""
    @State private var drafts: [PasteTripParser.Draft] = []
    @State private var isShowingPreview: Bool = false
    
    private let parser = PasteTripParser()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("粘贴内容") {
                    TextEditor(text: $rawText)
                        .frame(minHeight: 180)
                }
                
                Section {
                    Button("解析预览") {
                        drafts = parser.parse(text: rawText)
                        isShowingPreview = true
                    }
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("粘贴解析")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingPreview) {
                PasteImportPreviewSheet(trip: trip, drafts: $drafts)
            }
        }
    }
}

private struct PasteImportPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    @Binding var drafts: [PasteTripParser.Draft]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($drafts) { $d in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(d.kind == .itinerary ? "行程" : "支出")
                                    .font(.caption.weight(.medium))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(CuteTheme.gradient)
                                    .clipShape(Capsule())
                                Spacer()
                                Text(d.date, format: d.hasTime ? .dateTime.month().day().hour().minute() : .dateTime.month().day())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField(d.kind == .itinerary ? "行程标题" : "备注/项目", text: $d.title)
                            
                            if d.kind == .expense {
                                HStack {
                                    TextField("金额", value: Binding(get: { d.amount ?? 0 }, set: { d.amount = $0 }), format: .number)
                                        .keyboardType(.decimalPad)
                                    Picker("币种", selection: $d.currency) {
                                        Text("CNY").tag("CNY")
                                        Text("USD").tag("USD")
                                        Text("EUR").tag("EUR")
                                        Text("JPY").tag("JPY")
                                    }
                                    .labelsHidden()
                                }
                                
                                Picker("类别", selection: $d.category) {
                                    Text("机票").tag("机票")
                                    Text("餐饮").tag("餐饮")
                                    Text("住宿").tag("住宿")
                                    Text("交通").tag("交通")
                                    Text("门票").tag("门票")
                                    Text("其他").tag("其他")
                                }
                                
                                Toggle("指定时间", isOn: $d.hasTime)
                                DatePicker("发生时间", selection: $d.date, displayedComponents: d.hasTime ? [.date, .hourAndMinute] : [.date])
                                
                                if d.category == "住宿" {
                                    Stepper("晚数 \(d.nights ?? 1)", value: Binding(get: { d.nights ?? 1 }, set: { d.nights = $0 }), in: 1...60)
                                }
                            } else {
                                DatePicker("时间", selection: $d.date, displayedComponents: [.date, .hourAndMinute])
                            }
                        }
                        .padding(14)
                        .background(CuteTheme.cardBackground())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete { indexSet in
                        drafts.remove(atOffsets: indexSet)
                    }
                } header: {
                    Text("预览（可修改/删除）")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(CuteTheme.background)
            .navigationTitle("导入预览")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("返回") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        importDrafts()
                        dismiss()
                    }
                    .disabled(drafts.isEmpty)
                }
            }
        }
    }
    
    private func importDrafts() {
        for d in drafts {
            switch d.kind {
            case .itinerary:
                let item = ItineraryItem(title: d.title.isEmpty ? "未命名行程" : d.title, date: d.date)
                modelContext.insert(item)
                trip.itinerary.append(item)
            case .expense:
                let amount = d.amount ?? 0
                let category = d.category
                let occurredAt: Date? = d.hasTime ? d.date : nil
                let stayStart: Date? = category == "住宿" ? Calendar.current.startOfDay(for: d.date) : nil
                let nights: Int? = category == "住宿" ? (d.nights ?? 1) : nil
                
                let exp = Expense(
                    amount: amount,
                    currency: d.currency,
                    note: d.title,
                    category: category,
                    occurredAt: occurredAt,
                    stayStartDate: stayStart,
                    nights: nights
                )
                modelContext.insert(exp)
                trip.expenses.append(exp)
            }
        }
        try? modelContext.save()
    }
}
