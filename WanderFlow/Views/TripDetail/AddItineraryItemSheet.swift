import SwiftUI
import SwiftData
import MapKit

struct AddItineraryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var trip: Trip
    var itemToEdit: ItineraryItem?
    
    private enum FocusField: Hashable {
        case title
    }
    
    @State private var title: String = ""
    @State private var date: Date = .init()
    @State private var placeName: String?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var cityName: String?
    @State private var cityCoord: CLLocationCoordinate2D?
    @State private var setAsTripDefaultCity: Bool = false
    @State private var isShowingCityPicker: Bool = false
    @State private var isShowingPlacePicker: Bool = false
    @FocusState private var focusedField: FocusField?
    
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
        } else {
            if let name = trip.defaultCityName, let lat = trip.defaultCityLatitude, let lon = trip.defaultCityLongitude {
                _cityName = State(initialValue: name)
                _cityCoord = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("addItinerary.section") {
                    TextField("addItinerary.field.title", text: $title)
                        .focused($focusedField, equals: .title)
                    DatePicker("addItinerary.field.time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Button {
                        openCityPicker()
                    } label: {
                        HStack {
                            Text("addItinerary.field.city")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(cityName ?? NSLocalizedString("addItinerary.city.placeholder", comment: ""))
                                .foregroundColor(cityName == nil ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if let cityName, let defaultCity = trip.defaultCityName, cityName != defaultCity {
                        Toggle("addItinerary.toggle.setDefaultCity", isOn: $setAsTripDefaultCity)
                    }
                    
                    Button {
                        openPlacePicker()
                    } label: {
                        HStack {
                            Text("addItinerary.field.place")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(placeName ?? NSLocalizedString("addItinerary.place.placeholder", comment: ""))
                                .foregroundColor(placeName == nil ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
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
            .navigationTitle(itemToEdit == nil ? NSLocalizedString("addItinerary.title.add", comment: "") : NSLocalizedString("addItinerary.title.edit", comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .tint(trip.resolvedStyle.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
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
                        
                        if trip.defaultCityName == nil, let name = cityName, let coord = cityCoord {
                            trip.defaultCityName = name
                            trip.defaultCityLatitude = coord.latitude
                            trip.defaultCityLongitude = coord.longitude
                        } else if setAsTripDefaultCity, let name = cityName, let coord = cityCoord {
                            trip.defaultCityName = name
                            trip.defaultCityLatitude = coord.latitude
                            trip.defaultCityLongitude = coord.longitude
                        }
                        
                        try? modelContext.save()
                        dismiss()
                    }
                    .tint(trip.resolvedStyle.accent)
                }
            }
            .navigationDestination(isPresented: $isShowingCityPicker) {
                CityPickerView { name, coord in
                    cityName = name
                    cityCoord = coord
                    if trip.defaultCityName == nil {
                        setAsTripDefaultCity = true
                    } else if let defaultCity = trip.defaultCityName, defaultCity != name {
                        setAsTripDefaultCity = false
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingPlacePicker) {
                PlacePickerView(regionBias: regionBiasForSearch()) { name, coord in
                    placeName = name
                    coordinate = coord
                }
            }
        }
    }

    private func openCityPicker() {
        let shouldWait = focusedField != nil
        focusedField = nil
        dismissKeyboard()
        if shouldWait {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                isShowingCityPicker = true
            }
        } else {
            DispatchQueue.main.async {
                isShowingCityPicker = true
            }
        }
    }
    
    private func openPlacePicker() {
        let shouldWait = focusedField != nil
        focusedField = nil
        dismissKeyboard()
        if shouldWait {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                isShowingPlacePicker = true
            }
        } else {
            DispatchQueue.main.async {
                isShowingPlacePicker = true
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func regionBiasForSearch() -> MKCoordinateRegion? {
        if let lat = cityCoord?.latitude, let lon = cityCoord?.longitude {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        return nil
    }
}
