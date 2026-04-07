import SwiftUI
import SwiftData
import MapKit

struct AddItineraryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    var itemToEdit: ItineraryItem?
    
    @State private var title: String = ""
    @State private var date: Date = .init()
    @State private var placeName: String?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var cityName: String?
    @State private var cityCoord: CLLocationCoordinate2D?
    
    init(trip: Trip, itemToEdit: ItineraryItem? = nil) {
        self.trip = trip
        self.itemToEdit = itemToEdit
        
        // Initialize state if editing
        if let item = itemToEdit {
            _title = State(initialValue: item.title)
            _date = State(initialValue: item.date)
            _placeName = State(initialValue: item.placeName)
            if let lat = item.latitude, let lon = item.longitude {
                _coordinate = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
            _cityName = State(initialValue: item.cityName)
            if let lat = item.cityLatitude, let lon = item.cityLongitude {
                _cityCoord = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("行程") {
                    TextField("标题", text: $title)
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    NavigationLink {
                        CityPickerView { name, coord in
                            cityName = name
                            cityCoord = coord
                        }
                    } label: {
                        HStack {
                            Text("城市")
                            Spacer()
                            Text(cityName ?? "选择城市")
                                .foregroundColor(cityName == nil ? .secondary : .primary)
                        }
                    }
                    NavigationLink {
                        PlacePickerView(regionBias: regionBiasForSearch()) { name, coord in
                            placeName = name
                            coordinate = coord
                        }
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
        }
    }

    private func regionBiasForSearch() -> MKCoordinateRegion? {
        if let lat = cityCoord?.latitude, let lon = cityCoord?.longitude {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        return nil
    }
}
