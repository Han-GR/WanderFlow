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
    @State private var newTitle: String = ""
    @State private var newStart: Date = .init()
    @State private var newEnd: Date = .init()
    @State private var newColorHex: String = "#4DA3FF"
    private let themeColors: [(name: String, hex: String)] = [
        ("天空蓝", "#4DA3FF"),
        ("森林绿", "#2ECC71"),
        ("夕阳橙", "#FF8A3D")
    ]
    
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
                        Text("创建你的第一段旅程")
                            .font(.title3.weight(.semibold))
                        Text("记录行程与花销，让出行更轻松")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                        Button {
                            isPresentingNewTrip = true
                        } label: {
                            Text("新建旅行")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(trips) { trip in
                            NavigationLink(value: trip) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: trip.coverColorHex ?? "#4DA3FF"))
                                        .frame(width: 12, height: 12)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(trip.title)
                                            .font(.headline)
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                            Text(trip.createdAt, style: .date)
                                        }
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(14)
                                .background(CuteTheme.cardBackground())
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(trips[index])
                            }
                            try? modelContext.save()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(CuteTheme.background)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                        ToolbarItem {
                            Button {
                                isPresentingNewTrip = true
                            } label: {
                                Label("新建旅行", systemImage: "plus")
                            }
                        }
                    }
                    .navigationDestination(for: Trip.self) { trip in
                        TripDetailView(trip: trip)
                    }
                }
            }
            .background(CuteTheme.background)
            .sheet(isPresented: $isPresentingNewTrip) {
                NavigationStack {
                    Form {
                        Section("基本信息") {
                            TextField("旅行标题", text: $newTitle)
                            DatePicker("开始日期", selection: $newStart, displayedComponents: .date)
                            DatePicker("结束日期", selection: $newEnd, displayedComponents: .date)
                            VStack(alignment: .leading) {
                                Text("主题颜色")
                                HStack {
                                    ForEach(themeColors, id: \.hex) { item in
                                        Button {
                                            newColorHex = item.hex
                                        } label: {
                                            Circle()
                                                .fill(Color(hex: item.hex))
                                                .frame(width: 28, height: 28)
                                                .overlay(
                                                    Circle()
                                                        .stroke(newColorHex == item.hex ? Color.primary : .clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("新建旅行")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { isPresentingNewTrip = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("创建") {
                                let trip = Trip(title: newTitle.isEmpty ? "未命名旅行" : newTitle, startDate: newStart, endDate: newEnd, coverColorHex: newColorHex)
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
