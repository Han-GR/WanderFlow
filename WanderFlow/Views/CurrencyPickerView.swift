import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCurrencyCode: String
    @State private var searchText: String = ""
    @State private var filteredItems: [CurrencyItem]
    @State private var searchTask: Task<Void, Never>?
    
    private let allItems: [CurrencyItem]
    
    init(selectedCurrencyCode: Binding<String>) {
        self._selectedCurrencyCode = selectedCurrencyCode
        let items = CurrencyCatalog.items(locale: .current)
        self.allItems = items
        self._filteredItems = State(initialValue: items)
    }
    
    var body: some View {
        List {
            ForEach(filteredItems) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.code)
                            .font(AppTypography.sectionTitle)
                        Text(item.name)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if item.code == selectedCurrencyCode {
                        Image(systemName: "checkmark")
                            .font(AppTypography.body.weight(.semibold))
                            .foregroundColor(CuteTheme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    select(item)
                }
            }
        }
        .navigationTitle("currencyPicker.title")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "currencyPicker.search.prompt")
        .tunedSearchInput()
        .searchInputStyle()
        .scrollDismissesKeyboard(.never)
        .onChange(of: searchText) { _, newValue in
            let q = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty {
                filteredItems = allItems
                return
            }
            Debounce.schedule(task: &searchTask, delayNanoseconds: 200_000_000) {
                filteredItems = CurrencyCatalog.filter(items: allItems, query: q)
            }
        }
    }
    
    private func select(_ item: CurrencyItem) {
        selectedCurrencyCode = item.code
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.async {
            dismiss()
        }
    }
}

private struct CurrencyItem: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let nameKey: String
    
    init(code: String, name: String) {
        self.id = code
        self.code = code
        self.name = name
        self.nameKey = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

private enum CurrencyCatalog {
    static func items(locale: Locale) -> [CurrencyItem] {
        Locale.commonISOCurrencyCodes
            .sorted()
            .map { code in
                let name = locale.localizedString(forCurrencyCode: code) ?? ""
                return CurrencyItem(code: code, name: name)
            }
    }
    
    static func filter(items: [CurrencyItem], query: String) -> [CurrencyItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return items }
        let upper = trimmed.uppercased()
        let key = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        
        return items.filter { item in
            if item.code.contains(upper) { return true }
            return item.nameKey.contains(key)
        }
    }
}
