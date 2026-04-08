import SwiftUI
import SwiftData

struct TripEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    
    @State private var title: String = ""
    @State private var startDate: Date = .init()
    @State private var endDate: Date = .init()
    @State private var style: TripStyle = .fresh
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("旅行标题", text: $title)
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    Picker("旅行风格", selection: $style) {
                        ForEach(TripStyle.allCases) { s in
                            Text(s.title).tag(s)
                        }
                    }
                }
            }
            .navigationTitle("编辑旅行")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .tint(trip.resolvedStyle.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        trip.title = title.isEmpty ? trip.title : title
                        trip.startDate = startDate
                        trip.endDate = endDate
                        trip.styleRaw = style.rawValue
                        trip.coverColorHex = style.legacyCoverHex
                        try? modelContext.save()
                        dismiss()
                    }
                    .tint(trip.resolvedStyle.accent)
                }
            }
            .onAppear {
                title = trip.title
                startDate = trip.startDate ?? Date()
                endDate = trip.endDate ?? Date()
                style = trip.resolvedStyle
            }
        }
    }
}
