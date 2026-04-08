import SwiftUI

enum TripStyle: String, CaseIterable, Identifiable {
    case fresh
    case warm
    case forest
    case night
    case ocean
    case nature
    case drive
    case relax
    case healing
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .fresh: return "城市"
        case .warm: return "美食"
        case .forest: return "户外"
        case .nature: return "自然"
        case .ocean: return "海边"
        case .drive: return "自驾"
        case .night: return "夜游"
        case .relax: return "休闲"
        case .healing: return "治愈"
        }
    }
    
    var systemImage: String {
        switch self {
        case .fresh: return "building.2.fill"
        case .warm: return "fork.knife"
        case .forest: return "figure.hiking"
        case .nature: return "leaf.fill"
        case .ocean: return "beach.umbrella.fill"
        case .drive: return "car.fill"
        case .night: return "moon.stars.fill"
        case .relax: return "sofa.fill"
        case .healing: return "heart.fill"
        }
    }
    
    var accent: Color {
        switch self {
        case .fresh: return Color(hex: "#4DA3FF")
        case .warm: return Color(hex: "#FF8A3D")
        case .forest: return Color(hex: "#B14A3A")
        case .nature: return Color(hex: "#34C759")
        case .ocean: return Color(hex: "#00B8D9")
        case .drive: return Color(hex: "#7C5CFC")
        case .night: return Color(hex: "#6C63FF")
        case .relax: return Color(hex: "#A2845E")
        case .healing: return Color(hex: "#FF6FAE")
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .fresh:
            return LinearGradient(colors: [Color(hex: "#4DA3FF").opacity(0.22), Color(hex: "#FF94C2").opacity(0.18), Color(hex: "#B59DFF").opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            return LinearGradient(colors: [Color(hex: "#FF8A3D").opacity(0.22), Color(hex: "#FFCC66").opacity(0.18), Color(hex: "#FF6B8B").opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(colors: [Color(hex: "#B14A3A").opacity(0.22), Color(hex: "#E08A6C").opacity(0.18), Color(hex: "#F4D3B0").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .nature:
            return LinearGradient(colors: [Color(hex: "#34C759").opacity(0.22), Color(hex: "#A8E063").opacity(0.18), Color(hex: "#56CCF2").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .night:
            return LinearGradient(colors: [Color(hex: "#6C63FF").opacity(0.22), Color(hex: "#2D2A73").opacity(0.18), Color(hex: "#FF94C2").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:
            return LinearGradient(colors: [Color(hex: "#00B8D9").opacity(0.22), Color(hex: "#4DA3FF").opacity(0.18), Color(hex: "#2ECC71").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .drive:
            return LinearGradient(colors: [Color(hex: "#7C5CFC").opacity(0.22), Color(hex: "#4DA3FF").opacity(0.16), Color(hex: "#00B8D9").opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .relax:
            return LinearGradient(colors: [Color(hex: "#A2845E").opacity(0.22), Color(hex: "#D1BFA7").opacity(0.18), Color(hex: "#FF94C2").opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .healing:
            return LinearGradient(colors: [Color(hex: "#FF6FAE").opacity(0.22), Color(hex: "#FFB6D5").opacity(0.18), Color(hex: "#B59DFF").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var legacyCoverHex: String {
        switch self {
        case .fresh: return "#4DA3FF"
        case .warm: return "#FF8A3D"
        case .forest: return "#B14A3A"
        case .nature: return "#34C759"
        case .ocean: return "#00B8D9"
        case .drive: return "#7C5CFC"
        case .night: return "#6C63FF"
        case .relax: return "#A2845E"
        case .healing: return "#FF6FAE"
        }
    }
}

extension Trip {
    var resolvedStyle: TripStyle {
        if let raw = styleRaw, let s = TripStyle(rawValue: raw) {
            return s
        }
        if let hex = coverColorHex?.uppercased() {
            if hex.contains("FF8A3D") { return .warm }
            if hex.contains("2ECC71") { return .forest }
            if hex.contains("B14A3A") { return .forest }
            if hex.contains("34C759") { return .nature }
            if hex.contains("7C5CFC") { return .drive }
            if hex.contains("6C63FF") { return .night }
            if hex.contains("00B8D9") { return .ocean }
            if hex.contains("A2845E") { return .relax }
            if hex.contains("FF6FAE") { return .healing }
        }
        return .fresh
    }
}
