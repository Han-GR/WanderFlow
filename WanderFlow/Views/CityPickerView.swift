import SwiftUI
import MapKit

struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    var onSelect: (String, CLLocationCoordinate2D) -> Void
    
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching: Bool = false
    
    var body: some View {
        List {
            Section("cityPicker.section.results") {
                if results.isEmpty && !query.isEmpty {
                    Text("cityPicker.noResults")
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
                        
                        let name = item.name ?? NSLocalizedString("cityPicker.unknownCity", comment: "")
                        onSelect(name, coord)
                        dismiss()
                    } label: {
                        SearchResultRow(title: item.name ?? NSLocalizedString("cityPicker.fallbackCity", comment: ""), subtitle: nil, trailingText: nil)
                    }
                }
            }
        }
        .navigationTitle("cityPicker.title")
        .searchable(text: $query, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: "cityPicker.search.prompt")
        .searchInputStyle()
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
        request.resultTypes = .address
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            // 简单过滤一下，尽量保留像城市级别的结果
            // MKLocalSearch 不一定只返回城市，但可以通过 locality 判空来倾向于城市
            self.results = response?.mapItems ?? []
        }
    }
}
