import SwiftUI
import SwiftData

struct ItineraryListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    @Binding var editingItem: ItineraryItem?
    
    private var groupedItinerary: [(Date, [ItineraryItem])] {
        let sorted = trip.itinerary.sorted { $0.date < $1.date }
        let grouped = Dictionary(grouping: sorted) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        List {
            ForEach(groupedItinerary, id: \.0) { date, items in
                Section(header: Text(date, format: .dateTime.weekday().month().day())) {
                    ForEach(items) { item in
                        Button {
                            editingItem = item
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text(item.date, format: .dateTime.hour().minute())
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 50, alignment: .trailing)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let city = item.cityName {
                                        Text(city)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    if let place = item.placeName {
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.and.ellipse")
                                            Text(place)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle()) // 扩大点击区域
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain) // 消除 List 默认点击样式干扰
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                                if let idx = trip.itinerary.firstIndex(where: { $0.id == item.id }) {
                                    trip.itinerary.remove(at: idx)
                                }
                                try? modelContext.save()
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            if trip.itinerary.isEmpty {
                Section {
                    ContentUnavailableView("还没有行程", systemImage: "calendar.badge.plus", description: Text("点击下方按钮添加你的第一个行程安排"))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
