import SwiftUI

enum CuteTheme {
    static let accent = Color(red: 0.33, green: 0.55, blue: 1.0)
    static let tintPink = Color(red: 1.0, green: 0.58, blue: 0.80)
    static let tintPurple = Color(red: 0.72, green: 0.56, blue: 1.0)
    
    static var background: Color { Color(uiColor: .systemGroupedBackground) }
    
    static var gradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.22), tintPink.opacity(0.18), tintPurple.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var cardStroke: Color {
        Color.black.opacity(0.06)
    }
    
    static func cardBackground(cornerRadius: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(cardStroke, lineWidth: 1)
            )
    }
}
