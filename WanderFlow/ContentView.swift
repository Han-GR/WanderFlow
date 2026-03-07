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

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var selection: DetailTab = .itinerary
    @State private var isShowingTripEditor: Bool = false
    @State private var isShowingAddItinerary: Bool = false
    @State private var isShowingAddExpense: Bool = false
    @State private var isConfirmingDelete: Bool = false
    @State private var editingItem: ItineraryItem?
    
    enum DetailTab: String, CaseIterable {
        case itinerary = "行程"
        case expenses = "支出"
    }
    
    private var groupedItinerary: [(Date, [ItineraryItem])] {
        let sorted = trip.itinerary.sorted { $0.date < $1.date }
        let grouped = Dictionary(grouping: sorted) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("视图切换", selection: $selection) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            if selection == .itinerary {
                ItineraryListView
            } else {
                ExpenseListView(trip: trip)
            }
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("编辑旅行") { isShowingTripEditor = true }
                    Button("删除旅行", role: .destructive) { isConfirmingDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    if selection == .itinerary {
                        Button {
                            editingItem = nil
                            isShowingAddItinerary = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("添加行程")
                            }
                            .font(.headline)
                        }
                    } else {
                        Button {
                            isShowingAddExpense = true
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("记一笔")
                            }
                            .font(.headline)
                        }
                    }
                    Spacer()
                }
            }
        }
        .confirmationDialog("删除这趟旅行？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("删除旅行", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingTripEditor) {
            TripEditorSheet(trip: trip)
        }
        .sheet(isPresented: $isShowingAddItinerary) {
            AddItineraryItemSheet(trip: trip, itemToEdit: editingItem)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingAddExpense) {
            AddExpenseSheet(trip: trip)
                .presentationDetents([.medium])
        }
        // 当 editingItem 变化时自动触发 Sheet
        .onChange(of: editingItem) { _, newItem in
            if newItem != nil {
                isShowingAddItinerary = true
            }
        }
    }
    
    private var ItineraryListView: some View {
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
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                                if let idx = trip.itinerary.firstIndex(where: { $0.id == item.id }) {
                                    trip.itinerary.remove(at: idx)
                                }
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

struct TripHeaderCard: View {
    var trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: trip.coverColorHex ?? "#4DA3FF"))
                    .frame(width: 12, height: 12)
                Text(trip.title)
                    .font(.title3.weight(.semibold))
                Spacer()
            }
            Text(dateRangeText)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Text("行程 \(trip.itinerary.count) · 支出 \(trip.expenses.count)")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var dateRangeText: String {
        guard let start = trip.startDate, let end = trip.endDate else {
            return "未设置日期"
        }
        return "\(start.formatted(date: .abbreviated, time: .omitted)) · \(end.formatted(date: .abbreviated, time: .omitted))"
    }
}

struct TripPrimaryActions: View {
    var onAddItinerary: () -> Void
    var onAddExpense: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onAddItinerary()
            } label: {
                Label("添加行程", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                onAddExpense()
            } label: {
                Label("记一笔", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct TripSummarySection: View {
    var trip: Trip
    
    var body: some View {
        VStack(spacing: 12) {
            TripSummaryCard(
                title: "下一站",
                systemImage: "location.fill",
                primaryText: nextUpTitle,
                secondaryText: nextUpSubtitle
            )
            TripSummaryCard(
                title: "今日安排",
                systemImage: "calendar",
                primaryText: todayTitle,
                secondaryText: todaySubtitle
            )
            TripSummaryCard(
                title: "费用概览",
                systemImage: "creditcard",
                primaryText: spendTitle,
                secondaryText: spendSubtitle
            )
        }
    }
    
    private var calendar: Calendar { .current }
    
    private var sortedItinerary: [ItineraryItem] {
        trip.itinerary.sorted { $0.date < $1.date }
    }
    
    private var nextUp: ItineraryItem? {
        let now = Date()
        return sortedItinerary.first { $0.date >= now }
    }
    
    private var nextUpTitle: String {
        nextUp?.title ?? "还没有行程安排"
    }
    
    private var nextUpSubtitle: String {
        guard let item = nextUp else { return "点击“添加行程”开始规划" }
        let place = item.placeName.map { " · \($0)" } ?? ""
        return "\(item.date.formatted(date: .abbreviated, time: .omitted))\(place)"
    }
    
    private var todayItems: [ItineraryItem] {
        let today = calendar.startOfDay(for: Date())
        return sortedItinerary.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    private var todayTitle: String {
        todayItems.isEmpty ? "今天没有安排" : "今天 \(todayItems.count) 个安排"
    }
    
    private var todaySubtitle: String {
        guard !todayItems.isEmpty else { return "点击“添加行程”添加今天的地点" }
        return todayItems.prefix(2).map(\.title).joined(separator: " · ")
    }
    
    private var currencyTotals: [(String, Double)] {
        let totals = trip.expenses.reduce(into: [String: Double]()) { dict, exp in
            dict[exp.currency, default: 0] += exp.amount
        }
        return totals
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    private var spendTitle: String {
        guard !currencyTotals.isEmpty else { return "还没有支出记录" }
        let top = currencyTotals.prefix(3).map { "\($0.0) \(String(format: "%.2f", $0.1))" }
        return top.joined(separator: " · ")
    }
    
    private var spendSubtitle: String {
        guard let latest = trip.expenses.sorted(by: { $0.createdAt > $1.createdAt }).first else {
            return "点击“记一笔”记录旅行开销"
        }
        let note = latest.note.isEmpty ? "最近一笔" : latest.note
        return "\(note) · \(String(format: "%.2f", latest.amount)) \(latest.currency)"
    }
}

struct TripSummaryCard: View {
    var title: String
    var systemImage: String
    var primaryText: String
    var secondaryText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            Text(primaryText)
                .font(.body.weight(.semibold))
            Text(secondaryText)
                .foregroundColor(.secondary)
                .font(.footnote)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TripQuickLinks: View {
    var trip: Trip
    
    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                ItineraryListView(trip: trip)
            } label: {
                HStack {
                    Text("查看全部行程")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            NavigationLink {
                ExpenseListView(trip: trip)
            } label: {
                HStack {
                    Text("查看全部账单")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .buttonStyle(.plain)
                    }
                }

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

struct AddItineraryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    var itemToEdit: ItineraryItem?
    
    @State private var title: String = ""
    @State private var date: Date = .init()
    @State private var placeName: String?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var isPickingPlace: Bool = false
    @State private var cityName: String?
    @State private var cityCoord: CLLocationCoordinate2D?
    @State private var isPickingCity: Bool = false
    
    init(trip: Trip, itemToEdit: ItineraryItem? = nil) {
        self.trip = trip
        self.itemToEdit = itemToEdit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("行程") {
                    TextField("标题", text: $title)
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Button {
                        isPickingCity = true
                    } label: {
                        HStack {
                            Text("城市")
                            Spacer()
                            Text(cityName ?? "选择城市")
                                .foregroundColor(cityName == nil ? .secondary : .primary)
                        }
                    }
                    Button {
                        isPickingPlace = true
                    } label: {
                        HStack {
                            Text("地点")
                            Spacer()
                            Text(placeName ?? "选择地点")
                                .foregroundColor(placeName == nil ? .secondary : .primary)
                        }
                    }
                }
            }
            .onAppear {
                if let item = itemToEdit, title.isEmpty {
                    title = item.title
                    date = item.date
                    placeName = item.placeName
                    if let lat = item.latitude, let lon = item.longitude {
                        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    cityName = item.cityName
                    if let lat = item.cityLatitude, let lon = item.cityLongitude {
                        cityCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
            }
            .navigationTitle(itemToEdit == nil ? "添加行程" : "编辑行程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard !title.isEmpty else { return }
                        let lat = coordinate?.latitude
                        let lon = coordinate?.longitude
                        
                        if let item = itemToEdit {
                            // Update existing
                            item.title = title
                            item.date = date
                            item.placeName = placeName
                            item.latitude = lat
                            item.longitude = lon
                            item.cityName = cityName
                            item.cityLatitude = cityCoord?.latitude
                            item.cityLongitude = cityCoord?.longitude
                        } else {
                            // Create new
                            let item = ItineraryItem(
                                title: title,
                                date: date,
                                placeName: placeName,
                                latitude: lat,
                                longitude: lon,
                                cityName: cityName,
                                cityLatitude: cityCoord?.latitude,
                                cityLongitude: cityCoord?.longitude
                            )
                            modelContext.insert(item)
                            trip.itinerary.append(item)
                        }
                        
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isPickingCity) {
                CityPickerView { name, coord in
                    cityName = name
                    cityCoord = coord
                    // 切换城市后，如果地点不在新城市范围内，或许可以考虑清空地点（可选）
                }
            }
            .sheet(isPresented: $isPickingPlace) {
                PlacePickerView(regionBias: regionBiasForSearch()) { name, coord in
                    placeName = name
                    coordinate = coord
                }
            }
        }
    }

    private func regionBiasForSearch() -> MKCoordinateRegion? {
        if let lat = cityCoord?.latitude, let lon = cityCoord?.longitude {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        return nil
    }
}

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var currency: String = "CNY"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("支出") {
                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("备注", text: $note)
                    Picker("币种", selection: $currency) {
                        Text("CNY").tag("CNY")
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("JPY").tag("JPY")
                    }
                }
            }
            .navigationTitle("记一笔")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let amount = Double(amountText) else { return }
                        let exp = Expense(amount: amount, currency: currency, note: note)
                        modelContext.insert(exp)
                        trip.expenses.append(exp)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ItineraryListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    private var sorted: [ItineraryItem] {
        trip.itinerary.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        List {
            ForEach(sorted) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text(item.date, style: .date)
                        if let place = item.placeName, !place.isEmpty {
                            Text("·")
                            Text(place)
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.footnote)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let item = sorted[index]
                    trip.itinerary.removeAll { $0 === item }
                    modelContext.delete(item)
                }
                try? modelContext.save()
            }
        }
        .navigationTitle("全部行程")
        .toolbar { EditButton() }
    }
}

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    private var sortedExpenses: [Expense] {
        trip.expenses.sorted { $0.createdAt > $1.createdAt }
    }
    
    private var currencyTotals: [(String, Double)] {
        let totals = trip.expenses.reduce(into: [String: Double]()) { dict, exp in
            dict[exp.currency, default: 0] += exp.amount
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        List {
            if !currencyTotals.isEmpty {
                Section("总支出") {
                    ForEach(currencyTotals, id: \.0) { currency, amount in
                        HStack {
                            Text(currency)
                            Spacer()
                            Text(amount, format: .currency(code: currency))
                        }
                    }
                }
            }
            
            Section("明细") {
                ForEach(sortedExpenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.note.isEmpty ? "支出" : expense.note)
                                .font(.headline)
                            Text(expense.createdAt, format: .dateTime.month().day())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(expense.amount, format: .currency(code: expense.currency))
                            .foregroundColor(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(expense)
                            if let idx = trip.expenses.firstIndex(where: { $0.id == expense.id }) {
                                trip.expenses.remove(at: idx)
                            }
                            try? modelContext.save()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            
            if trip.expenses.isEmpty {
                Section {
                    ContentUnavailableView("还没有支出", systemImage: "creditcard", description: Text("点击底部按钮记录第一笔开销"))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
