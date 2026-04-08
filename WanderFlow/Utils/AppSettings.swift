import Foundation

enum AppSettings {
    static let defaultCurrencyCodeKey = "defaultCurrencyCode"
    
    static func resolvedDefaultCurrencyCode(userDefaults: UserDefaults = .standard, locale: Locale = .current) -> String {
        if let stored = userDefaults.string(forKey: defaultCurrencyCodeKey), !stored.isEmpty {
            return stored
        }
        
        if #available(iOS 16.0, *) {
            if let id = locale.currency?.identifier, !id.isEmpty {
                return id
            }
        } else {
            if let code = locale.currencyCode, !code.isEmpty {
                return code
            }
        }
        
        return "CNY"
    }
}
