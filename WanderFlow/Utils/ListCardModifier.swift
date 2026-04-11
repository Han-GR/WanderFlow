import SwiftUI

struct ListCardModifier: ViewModifier {
    var insets: EdgeInsets = CuteTheme.listCardInsets
    
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(CuteTheme.cardBackground())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(insets)
    }
}

struct AccentListCardModifier: ViewModifier {
    var accent: Color
    var insets: EdgeInsets = CuteTheme.listCardInsets
    var fillOpacity: Double = 0.08
    var strokeOpacity: Double = 0.10
    
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: CuteTheme.cardCornerRadius, style: .continuous)
                    .fill(accent.opacity(fillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: CuteTheme.cardCornerRadius, style: .continuous)
                            .strokeBorder(accent.opacity(strokeOpacity), lineWidth: 1)
                    )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(insets)
    }
}

extension View {
    func listCard(insets: EdgeInsets = CuteTheme.listCardInsets) -> some View {
        modifier(ListCardModifier(insets: insets))
    }
    
    func accentListCard(accent: Color, insets: EdgeInsets = CuteTheme.listCardInsets, fillOpacity: Double = 0.08, strokeOpacity: Double = 0.10) -> some View {
        modifier(AccentListCardModifier(accent: accent, insets: insets, fillOpacity: fillOpacity, strokeOpacity: strokeOpacity))
    }
}
