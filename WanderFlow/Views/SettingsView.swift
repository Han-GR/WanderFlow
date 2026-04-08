import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.defaultCurrencyCodeKey) private var defaultCurrencyCode: String = AppSettings.resolvedDefaultCurrencyCode()
    
    var body: some View {
        List {
            Section("基础设置") {
                NavigationLink {
                    CurrencyPickerView(selectedCurrencyCode: $defaultCurrencyCode)
                } label: {
                    HStack {
                        Text("默认货币")
                        Spacer()
                        Text(defaultCurrencyCode)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("设置")
    }
}

