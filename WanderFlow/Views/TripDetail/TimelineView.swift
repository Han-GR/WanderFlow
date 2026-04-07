import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    @Binding var editingItineraryItem: ItineraryItem?
    var onQuickAddExpense: ((ItineraryItem) -> Void)?
    
    private let calendar = Calendar.current
    @State private var itineraryToDelete: ItineraryItem?
    
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
                                    if let item = entry.itineraryItem {
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
                            editingItineraryItem = entry.itineraryItem
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing) {
                            if let itinerary = entry.itineraryItem {
                                Button(role: .destructive) {
                                    itineraryToDelete = itinerary
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            
            if trip.itinerary.isEmpty {
                Section {
                    ContentUnavailableView("还没有行程", systemImage: "calendar.badge.plus", description: Text("点击右上角 + 添加你的第一个行程安排"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(CuteTheme.background)
        .alert("删除这条行程？", isPresented: Binding(get: { itineraryToDelete != nil }, set: { if !$0 { itineraryToDelete = nil } })) {
            Button("删除", role: .destructive) {
                if let itineraryToDelete {
                    modelContext.delete(itineraryToDelete)
                    if let idx = trip.itinerary.firstIndex(where: { $0.id == itineraryToDelete.id }) {
                        trip.itinerary.remove(at: idx)
                    }
                    try? modelContext.save()
                }
                itineraryToDelete = nil
            }
            Button("取消", role: .cancel) {
                itineraryToDelete = nil
            }
        }
    }
    
    private var groupedEntries: [TimelineDayGroup] {
        let sorted = trip.itinerary.sorted { $0.date < $1.date }
        let grouped = Dictionary(grouping: sorted) { item in
            calendar.startOfDay(for: item.date)
        }
        return grouped
            .map { TimelineDayGroup(day: $0.key, entries: $0.value.map { TimelineEntry(itinerary: $0) }) }
            .sorted { $0.day < $1.day }
    }
}

private struct TimelineDayGroup {
    let day: Date
    let entries: [TimelineEntry]
}

private struct TimelineEntry: Identifiable {
    let id: AnyHashable
    
    let day: Date
    
    let title: String
    let subtitle: String?
    
    let itineraryItem: ItineraryItem?
    
    init(itinerary: ItineraryItem) {
        self.id = itinerary.id
        self.day = Calendar.current.startOfDay(for: itinerary.date)
        self.title = itinerary.title
        if let place = itinerary.placeName, !place.isEmpty {
            self.subtitle = place
        } else {
            self.subtitle = itinerary.cityName
        }
        self.itineraryItem = itinerary
    }
    
    var timeText: String {
        if let d = itineraryItem?.date {
            return d.formatted(date: .omitted, time: .shortened)
        }
        return "—"
    }
    
    var iconName: String {
        "mappin.and.ellipse"
    }
    
    var iconColor: Color {
        CuteTheme.accent
    }
}
