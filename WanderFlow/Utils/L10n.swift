import Foundation

enum L10n {
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
        return String(format: format, locale: Locale.current, arguments: arguments)
    }
}

