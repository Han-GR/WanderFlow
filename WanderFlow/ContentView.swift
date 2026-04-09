//
//  ContentView.swift
//  WanderFlow
//
//  Created by han han on 2026/3/6.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TripsView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

struct TripsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var isPresentingNewTrip: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var newTitle: String = ""
    @State private var newStart: Date = .init()
    @State private var newEnd: Date = .init()
    @State private var newStyle: TripStyle = .fresh
    @State private var tripToDelete: Trip?
    
    private let calendar = Calendar.current
    
    private struct TripYearSection: Identifiable {
        let year: Int
        let trips: [Trip]
        
        var id: Int { year }
    }
    
    private func sortDate(for trip: Trip) -> Date {
        trip.startDate ?? trip.createdAt
    }
    
    private var yearSections: [TripYearSection] {
        let sortedTrips = trips.sorted { sortDate(for: $0) > sortDate(for: $1) }
        let grouped = Dictionary(grouping: sortedTrips) { trip in
            calendar.component(.year, from: sortDate(for: trip))
        }
        return grouped.keys
            .sorted(by: >)
            .map { year in
                TripYearSection(year: year, trips: grouped[year] ?? [])
            }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(CuteTheme.gradient)
                                .frame(width: 88, height: 88)
                            Image(systemName: "sparkles")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(CuteTheme.accent)
                        }
                        Text("home.empty.title")
                            .font(AppTypography.pageTitle)
                        Text("home.empty.subtitle")
                            .foregroundColor(.secondary)
                            .font(AppTypography.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(yearSections) { section in
                            Section(header: Text(verbatim: L10n.format("home.trips.section.year", section.year))) {
                                ForEach(section.trips) { trip in
                                    NavigationLink(value: trip) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(trip.resolvedStyle.gradient)
                                                .frame(width: 12, height: 12)
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(trip.title)
                                                    .font(AppTypography.sectionTitle)
                                                HStack(spacing: 6) {
                                                    Image(systemName: "calendar")
                                                    Text(sortDate(for: trip), format: .dateTime.month().day())
                                                }
                                                .foregroundColor(.secondary)
                                                .font(AppTypography.caption)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .listCard(insets: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            tripToDelete = trip
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(CuteTheme.background)
                    .navigationDestination(for: Trip.self) { trip in
                        TripDetailView(trip: trip)
                    }
                }
            }
            .background(CuteTheme.background)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .alert("home.alert.deleteTrip.title", isPresented: Binding(get: { tripToDelete != nil }, set: { if !$0 { tripToDelete = nil } })) {
                Button("common.delete", role: .destructive) {
                    if let tripToDelete {
                        modelContext.delete(tripToDelete)
                        try? modelContext.save()
                    }
                    tripToDelete = nil
                }
                Button("common.cancel", role: .cancel) {
                    tripToDelete = nil
                }
            }
            .sheet(isPresented: $isPresentingNewTrip) {
                NavigationStack {
                    Form {
                        Section("home.newTrip.section.basic") {
                            TextField("home.newTrip.field.title", text: $newTitle)
                            DatePicker("home.newTrip.field.startDate", selection: $newStart, displayedComponents: .date)
                            DatePicker("home.newTrip.field.endDate", selection: $newEnd, displayedComponents: .date)
                            Picker("home.newTrip.field.style", selection: $newStyle) {
                                ForEach(TripStyle.allCases) { style in
                                    Label {
                                        Text(style.title)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    } icon: {
                                        Image(systemName: style.systemImage)
                                            .foregroundStyle(style.accent)
                                    }
                                    .tag(style)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .tint(newStyle.accent)
                        }
                    }
                    .navigationTitle("home.newTrip.title")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("common.cancel") { isPresentingNewTrip = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("home.newTrip.action.create") {
                                let trip = Trip(title: newTitle.isEmpty ? NSLocalizedString("home.trip.untitled", comment: "") : newTitle, startDate: newStart, endDate: newEnd, coverColorHex: newStyle.legacyCoverHex, styleRaw: newStyle.rawValue)
                                modelContext.insert(trip)
                                try? modelContext.save()
                                newTitle = ""
                                isPresentingNewTrip = false
                            }
                        }
                    }
                }
            }
        }
    }
}
