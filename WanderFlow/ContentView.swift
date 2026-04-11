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
    @AppStorage(AppSettings.homeLayoutKey) private var homeLayoutRaw: String = HomeLayout.grid.rawValue
    @State private var isPresentingNewTrip: Bool = false
    @State private var isShowingSettings: Bool = false
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
                    if homeLayout == .grid {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {
                                ForEach(yearSections) { section in
                                    Text(verbatim: L10n.format("home.trips.section.year", L10n.integerNoGrouping(section.year)))
                                        .font(AppTypography.sectionTitle)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                    
                                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                                        ForEach(section.trips) { trip in
                                            NavigationLink(value: trip) {
                                                TripGridCard(trip: trip, date: sortDate(for: trip))
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    tripToDelete = trip
                                                } label: {
                                                    Label("common.delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        .background(CuteTheme.background)
                        .navigationDestination(for: Trip.self) { trip in
                            TripDetailView(trip: trip)
                        }
                    } else {
                        List {
                            ForEach(yearSections) { section in
                                Section(header: Text(verbatim: L10n.format("home.trips.section.year", L10n.integerNoGrouping(section.year)))) {
                                    ForEach(section.trips) { trip in
                                        NavigationLink(value: trip) {
                                            HStack(spacing: 12) {
                                                Image(systemName: trip.resolvedStyle.systemImage)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(trip.resolvedStyle.accent)
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(trip.title)
                                                        .font(AppTypography.sectionTitle)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
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
                                        .accentListCard(accent: trip.resolvedStyle.accent, insets: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16), fillOpacity: 0.07, strokeOpacity: 0.10)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                tripToDelete = trip
                                            } label: {
                                                Label("common.delete", systemImage: "trash")
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
                NewTripSheet { title, startDate, endDate, style in
                    let trip = Trip(title: title, startDate: startDate, endDate: endDate, coverColorHex: style.legacyCoverHex, styleRaw: style.rawValue)
                    modelContext.insert(trip)
                    try? modelContext.save()
                    isPresentingNewTrip = false
                } onCancel: {
                    isPresentingNewTrip = false
                }
            }
        }
    }
    
    private var homeLayout: HomeLayout {
        HomeLayout(rawValue: homeLayoutRaw) ?? .grid
    }
    
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: 12, alignment: .topLeading)]
    }
}

private struct TripGridCard: View {
    var trip: Trip
    var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(trip.title)
                    .font(AppTypography.sectionTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                Image(systemName: trip.resolvedStyle.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(trip.resolvedStyle.accent)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(date, format: .dateTime.month().day())
            }
            .font(AppTypography.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: CuteTheme.cardCornerRadius, style: .continuous)
                .fill(trip.resolvedStyle.accent.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: CuteTheme.cardCornerRadius, style: .continuous)
                        .strokeBorder(trip.resolvedStyle.accent.opacity(0.14), lineWidth: 1)
                )
        )
        .aspectRatio(2, contentMode: .fit)
    }
}

private struct NewTripSheet: View {
    @State private var title: String = ""
    @State private var startDate: Date = .init()
    @State private var endDate: Date = .init()
    @State private var style: TripStyle = .fresh
    
    var onCreate: (String, Date, Date, TripStyle) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("home.newTrip.section.basic") {
                    TextField("home.newTrip.field.title", text: $title)
                    DatePicker("home.newTrip.field.startDate", selection: $startDate, displayedComponents: .date)
                    DatePicker("home.newTrip.field.endDate", selection: $endDate, displayedComponents: .date)
                    Picker("home.newTrip.field.style", selection: $style) {
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
                    .tint(style.accent)
                }
            }
            .navigationTitle("home.newTrip.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("home.newTrip.action.create") {
                        let name = title.isEmpty ? NSLocalizedString("home.trip.untitled", comment: "") : title
                        onCreate(name, startDate, endDate, style)
                    }
                }
            }
        }
    }
}
