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
                Section("home.newTrip.section.basic") {
                    TextField("home.newTrip.field.title", text: $title)
                        .tunedTextInput()
                    DatePicker("home.newTrip.field.startDate", selection: $startDate, displayedComponents: .date)
                    DatePicker("home.newTrip.field.endDate", selection: $endDate, displayedComponents: .date)
                    Picker("home.newTrip.field.style", selection: $style) {
                        ForEach(TripStyle.allCases) { s in
                            Text(s.title).tag(s)
                        }
                    }.tint(trip.resolvedStyle.accent)
                }
            }
            .navigationTitle("tripDetail.menu.more.editTrip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .tint(trip.resolvedStyle.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
