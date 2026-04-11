import SwiftUI
import MapKit
import CoreLocation

struct PlacePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    var onSelect: (String, CLLocationCoordinate2D) -> Void
    var regionBias: MKCoordinateRegion?
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching: Bool = false
    
    init(regionBias: MKCoordinateRegion? = nil, onSelect: @escaping (String, CLLocationCoordinate2D) -> Void) {
        self.regionBias = regionBias
        self.onSelect = onSelect
    }
    
    var body: some View {
        List {
            Section("placePicker.section.results") {
                if results.isEmpty && !query.isEmpty {
                    Text("placePicker.noResults")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(results, id: \.self) { item in
                    Button {
                        let coord: CLLocationCoordinate2D
                        if #available(iOS 26.0, *) {
                            coord = item.location.coordinate
                        } else {
                            coord = item.placemark.coordinate
                        }
                        onSelect(item.name ?? NSLocalizedString("placePicker.unknownPlace", comment: ""), coord)
                        dismiss()
                    } label: {
                        SearchResultRow(title: item.name ?? NSLocalizedString("placePicker.fallbackPlace", comment: ""), subtitle: nil, trailingText: distanceText(for: item))
                    }
                }
            }
        }
        .navigationTitle("placePicker.title")
        .searchable(text: $query, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: "placePicker.search.prompt")
        .tunedSearchInput()
        .searchInputStyle()
        .onSubmit(of: .search) {
            search()
        }
        .onAppear {
            DispatchQueue.main.async {
                isSearching = true
            }
            locationManager.request()
        }
        .onChange(of: query) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                results = []
                return
            }
            Debounce.schedule(task: &searchTask, delayNanoseconds: 300_000_000) { search() }
        }
    }
    
    private func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // 优先使用传入的城市/区域偏置
        if let region = regionBias {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            results = response?.mapItems ?? []
        }
    }
    
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000.0)
        }
    }
    
    private func distanceText(for item: MKMapItem) -> String? {
        guard let user = locationManager.coordinate else { return nil }
        if #available(iOS 26.0, *) {
            let dist = CLLocation(latitude: user.latitude, longitude: user.longitude)
                .distance(from: item.location)
            return formatDistance(dist)
        }
        guard let loc = item.placemark.location else { return nil }
        let dist = CLLocation(latitude: user.latitude, longitude: user.longitude)
            .distance(from: loc)
        return formatDistance(dist)
    }
}
