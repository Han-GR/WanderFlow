import Foundation

enum HomeLayout: String, CaseIterable, Identifiable {
    case grid
    case list
    
    var id: String { rawValue }
}

