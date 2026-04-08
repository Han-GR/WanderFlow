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
                        Text("点击 + 创建你的第一段旅程")
                            .font(AppTypography.pageTitle)
                        Text("记录行程与花销，让出行更轻松")
                            .foregroundColor(.secondary)
                            .font(AppTypography.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(trips) { trip in
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
                                            Text(trip.createdAt, style: .date)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .alert("删除这趟旅行？", isPresented: Binding(get: { tripToDelete != nil }, set: { if !$0 { tripToDelete = nil } })) {
                Button("删除旅行", role: .destructive) {
                    if let tripToDelete {
                        modelContext.delete(tripToDelete)
                        try? modelContext.save()
                    }
                    tripToDelete = nil
                }
                Button("取消", role: .cancel) {
                    tripToDelete = nil
                }
            }
            .sheet(isPresented: $isPresentingNewTrip) {
                NavigationStack {
                    Form {
                        Section("基本信息") {
                            TextField("旅行标题", text: $newTitle)
                            DatePicker("开始日期", selection: $newStart, displayedComponents: .date)
                            DatePicker("结束日期", selection: $newEnd, displayedComponents: .date)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("旅行风格")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(TripStyle.allCases) { style in
                                            Button {
                                                newStyle = style
                                            } label: {
                                                HStack(spacing: 10) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(style.gradient)
                                                            .frame(width: 34, height: 34)
                                                        Image(systemName: style.systemImage)
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundColor(style.accent)
                                                    }
                                                    Text(style.title)
                                                        .font(AppTypography.body.weight(.semibold))
                                                        .foregroundColor(.primary)
                                                    Spacer(minLength: 0)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .frame(width: 120)
                                                .background(CuteTheme.cardBackground(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(newStyle == style ? style.accent.opacity(0.55) : Color.clear, lineWidth: 2)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 2)
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
                                let trip = Trip(title: newTitle.isEmpty ? "未命名旅行" : newTitle, startDate: newStart, endDate: newEnd, coverColorHex: newStyle.legacyCoverHex, styleRaw: newStyle.rawValue)
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
