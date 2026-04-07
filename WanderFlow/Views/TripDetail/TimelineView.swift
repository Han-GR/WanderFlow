import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    @Binding var editingItineraryItem: ItineraryItem?
    @Binding var editingExpense: Expense?
    var onQuickAddExpense: ((ItineraryItem) -> Void)?
    var showExpenses: Bool = true
    
    private let calendar = Calendar.current
    
    var body: some View {
        List {
            ForEach(groupedEntries, id: \.day) { group in
                Section(header: Text(group.day, format: .dateTime.weekday().month().day())) {
                    ForEach(group.entries) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(entry.timeText)
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                                if entry.isAllDay {
                                    Text("全天")
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(minWidth: 52, alignment: .trailing)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Image(systemName: entry.iconName)
                                        .foregroundColor(entry.iconColor)
                                    Text(entry.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer(minLength: 0)
                                    if let amountText = entry.amountText {
                                        Text(amountText)
                                            .font(.headline)
                                            .monospacedDigit()
                                            .foregroundColor(.secondary)
                                    }
                                    if entry.kind == .itinerary, let item = entry.itineraryItem {
                                        Button {
                                            onQuickAddExpense?(item)
                                        } label: {
                                            Image(systemName: "banknote.fill")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 34, height: 34)
                                                .background(CuteTheme.gradient)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                if let subtitle = entry.subtitle, !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(CuteTheme.cardBackground())
                        .contentShape(Rectangle())
                        .onTapGesture {
                            switch entry.kind {
                            case .itinerary:
                                editingItineraryItem = entry.itineraryItem
                            case .expense, .lodgingAllocation:
                                editingExpense = entry.expense
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing) {
                            if let itinerary = entry.itineraryItem {
                                Button(role: .destructive) {
                                    modelContext.delete(itinerary)
                                    if let idx = trip.itinerary.firstIndex(where: { $0.id == itinerary.id }) {
                                        trip.itinerary.remove(at: idx)
                                    }
                                    try? modelContext.save()
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            } else if let expense = entry.expense {
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
                }
            }
            
            if trip.itinerary.isEmpty && trip.expenses.isEmpty {
                Section {
                    ContentUnavailableView("还没有记录", systemImage: "sparkles", description: Text("点击右上角 + 开始添加行程或支出"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(CuteTheme.background)
    }
    
    private var groupedEntries: [TimelineDayGroup] {
        let entries = timelineEntries()
        let grouped = Dictionary(grouping: entries) { entry in
            entry.day
        }
        return grouped
            .map { TimelineDayGroup(day: $0.key, entries: $0.value.sorted(by: sortEntries)) }
            .sorted { $0.day < $1.day }
    }
    
    private func sortEntries(_ a: TimelineEntry, _ b: TimelineEntry) -> Bool {
        if a.isAllDay != b.isAllDay {
            return a.isAllDay && !b.isAllDay
        }
        return a.sortDate < b.sortDate
    }
    
    private func timelineEntries() -> [TimelineEntry] {
        var result: [TimelineEntry] = []
        
        for item in trip.itinerary {
            result.append(TimelineEntry(itinerary: item))
        }
        
        if showExpenses {
            for exp in trip.expenses {
                if exp.category == "住宿", let start = exp.stayStartDate, let nights = exp.nights, nights > 0 {
                    let perNight = exp.amount / Double(nights)
                    for offset in 0..<nights {
                        if let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: start)) {
                            result.append(TimelineEntry(lodgingAllocationFrom: exp, day: day, perNightAmount: perNight))
                        }
                    }
                } else {
                    result.append(TimelineEntry(expense: exp))
                }
            }
        }
        
        return result
    }
}

private struct TimelineDayGroup {
    let day: Date
    let entries: [TimelineEntry]
}

private struct TimelineEntry: Identifiable {
    enum Kind {
        case itinerary
        case expense
        case lodgingAllocation
    }
    
    let id: AnyHashable
    let kind: Kind
    
    let day: Date
    let sortDate: Date
    let isAllDay: Bool
    
    let title: String
    let subtitle: String?
    
    let amount: Double?
    let currency: String?
    
    let itineraryItem: ItineraryItem?
    let expense: Expense?
    
    init(itinerary: ItineraryItem) {
        self.id = itinerary.id
        self.kind = .itinerary
        self.day = Calendar.current.startOfDay(for: itinerary.date)
        self.sortDate = itinerary.date
        self.isAllDay = false
        self.title = itinerary.title
        if let place = itinerary.placeName, !place.isEmpty {
            self.subtitle = place
        } else {
            self.subtitle = itinerary.cityName
        }
        self.amount = nil
        self.currency = nil
        self.itineraryItem = itinerary
        self.expense = nil
    }
    
    init(expense: Expense) {
        self.id = expense.id
        self.kind = .expense
        let date = expense.occurredAt ?? expense.createdAt
        self.day = Calendar.current.startOfDay(for: date)
        self.sortDate = date
        self.isAllDay = expense.occurredAt == nil
        self.title = expense.note.isEmpty ? expense.category : expense.note
        self.subtitle = expense.note.isEmpty ? nil : expense.category
        self.amount = expense.amount
        self.currency = expense.currency
        self.itineraryItem = nil
        self.expense = expense
    }
    
    init(lodgingAllocationFrom expense: Expense, day: Date, perNightAmount: Double) {
        self.id = AnyHashable(UUID())
        self.kind = .lodgingAllocation
        self.day = Calendar.current.startOfDay(for: day)
        self.sortDate = Calendar.current.startOfDay(for: day)
        self.isAllDay = true
        self.title = expense.note.isEmpty ? "住宿" : expense.note
        let nightsText = expense.nights.map { "\($0)晚" } ?? ""
        self.subtitle = nightsText.isEmpty ? "住宿分摊" : "住宿分摊 · \(nightsText)"
        self.amount = perNightAmount
        self.currency = expense.currency
        self.itineraryItem = nil
        self.expense = expense
    }
    
    var timeText: String {
        if isAllDay { return "—" }
        if let d = itineraryItem?.date {
            return d.formatted(date: .omitted, time: .shortened)
        }
        if let d = expense?.occurredAt {
            return d.formatted(date: .omitted, time: .shortened)
        }
        return "—"
    }
    
    var amountText: String? {
        guard let amount, let currency else { return nil }
        return amount.formatted(.currency(code: currency))
    }
    
    var iconName: String {
        switch kind {
        case .itinerary:
            return "mappin.and.ellipse"
        case .expense:
            return "creditcard"
        case .lodgingAllocation:
            return "bed.double"
        }
    }
    
    var iconColor: Color {
        switch kind {
        case .itinerary:
            return CuteTheme.accent
        case .expense:
            return .orange
        case .lodgingAllocation:
            return .purple
        }
    }
}
