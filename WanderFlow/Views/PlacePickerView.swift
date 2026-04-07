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
            Section("搜索结果") {
                if results.isEmpty && !query.isEmpty {
                    Text("无结果")
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
                        onSelect(item.name ?? "地点", coord)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "地点")
                            HStack(spacing: 6) {
                                if let user = locationManager.coordinate {
                                    if #available(iOS 26.0, *) {
                                        let dist = CLLocation(latitude: user.latitude, longitude: user.longitude)
                                            .distance(from: item.location)
                                        Text(formatDistance(dist))
                                    } else {
                                        if let loc = item.placemark.location {
                                            let dist = CLLocation(latitude: user.latitude, longitude: user.longitude)
                                                .distance(from: loc)
                                            Text(formatDistance(dist))
                                        }
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                            .font(.footnote)
                        }
                    }
                }
            }
        }
        .navigationTitle("选择地点")
        .searchable(text: $query, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索店铺或地点")
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .onSubmit(of: .search) {
            search()
        }
        .onAppear {
            DispatchQueue.main.async {
                isSearching = true
            }
        }
        .onChange(of: query) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            searchTask?.cancel()
            guard !trimmed.isEmpty else {
                results = []
                return
            }
            searchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }
                search()
            }
        }
        .onAppear {
            locationManager.request()
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
}
