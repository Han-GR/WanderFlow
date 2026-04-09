import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.defaultCurrencyCodeKey) private var defaultCurrencyCode: String = AppSettings.resolvedDefaultCurrencyCode()
    
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
        }
        .navigationTitle("settings.title")
    }
}
