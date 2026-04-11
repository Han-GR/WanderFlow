import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.defaultCurrencyCodeKey) private var defaultCurrencyCode: String = AppSettings.resolvedDefaultCurrencyCode()
    @AppStorage(AppSettings.homeLayoutKey) private var homeLayoutRaw: String = HomeLayout.grid.rawValue
    
    var body: some View {
        List {
            Section("settings.section.basic") {
                NavigationLink {
                    CurrencyPickerView(selectedCurrencyCode: $defaultCurrencyCode)
                } label: {
                    HStack {
                        Text("settings.defaultCurrency")
                        Spacer()
                        Text(defaultCurrencyCode)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("settings.section.home") {
                Picker("settings.homeLayout.title", selection: $homeLayoutRaw) {
                    Text("settings.homeLayout.grid")
                        .tag(HomeLayout.grid.rawValue)
                    Text("settings.homeLayout.list")
                        .tag(HomeLayout.list.rawValue)
                }
            }
        }
        .navigationTitle("settings.title")
    }
}
