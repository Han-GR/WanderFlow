import SwiftUI
import SwiftData

struct TripEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    
    @State private var title: String = ""
    @State private var startDate: Date = .init()
    @State private var endDate: Date = .init()
    @State private var colorHex: String = "#4DA3FF"
    
    private let themeColors: [(name: String, hex: String)] = [
        ("天空蓝", "#4DA3FF"),
        ("森林绿", "#2ECC71"),
        ("夕阳橙", "#FF8A3D")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("旅行标题", text: $title)
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    VStack(alignment: .leading) {
                        Text("主题颜色")
                        HStack {
                            ForEach(themeColors, id: \.hex) { item in
                                Button {
                                    colorHex = item.hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: item.hex))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(colorHex == item.hex ? Color.primary : .clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("编辑旅行")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        trip.title = title.isEmpty ? trip.title : title
                        trip.startDate = startDate
                        trip.endDate = endDate
                        trip.coverColorHex = colorHex
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                title = trip.title
                startDate = trip.startDate ?? Date()
                endDate = trip.endDate ?? Date()
                colorHex = trip.coverColorHex ?? "#4DA3FF"
            }
        }
    }
}
