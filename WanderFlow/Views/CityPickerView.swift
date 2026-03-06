import SwiftUI
import MapKit

struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    var onSelect: (String, CLLocationCoordinate2D) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("搜索城市", text: $query)
                            .submitLabel(.search)
                            .onSubmit { search() }
                        Button("搜索") { search() }
                    }
                }
                
                Section("搜索结果") {
                    if results.isEmpty && !query.isEmpty {
                        Text("无结果").foregroundColor(.secondary)
                    }
                    
                    ForEach(results, id: \.self) { item in
                        Button {
                            // 优先使用 item.location.coordinate
                            let coord = item.location.coordinate
                            // 使用 item.name 作为城市名
                            let name = item.name ?? "未知城市"
                            onSelect(name, coord)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "城市")
                                // 如果有地址详情（这里暂时省略，避免使用废弃的 placemark.title）
                                // 如果需要更详细地址，可以尝试 item.postalAddress (如果可用)
                                // 这里简单处理，仅显示名字
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择城市")
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
