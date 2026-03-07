//
//  ContentView.swift
//  WanderFlow
//
//  Created by han han on 2026/3/6.
//

import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TripsView()
                .tabItem {
                    Label("行程", systemImage: "list.bullet.rectangle")
                }
                .tag(0)
            MapView()
                .tabItem {
                    Label("足迹", systemImage: "map")
                }
                .tag(1)
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
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
                        Text("创建你的第一段旅程")
                            .font(.title3.weight(.semibold))
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
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: trip.coverColorHex ?? "#4DA3FF"))
                                            .frame(width: 10, height: 10)
                                        Text(trip.title)
                                            .font(.headline)
                                    }
                                    Text(trip.createdAt, style: .date)
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(trips[index])
                            }
                            try? modelContext.save()
                        }
                    }
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

struct MapView: View {
    @State private var position: MapCameraPosition = .automatic
    var body: some View {
        NavigationStack {
            Map(position: $position)
                .mapStyle(.standard)
                .ignoresSafeArea()
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("账户") {
                    Text("使用 iCloud 同步你的数据")
                }
                Section("统计") {
                    Text("去过的国家")
                    Text("旅行里程")
                }
                Section("设置") {
                    Text("偏好设置")
                }
            }
        }
    }
}

