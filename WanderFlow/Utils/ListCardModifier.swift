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

extension View {
    func listCard(insets: EdgeInsets = CuteTheme.listCardInsets) -> some View {
        modifier(ListCardModifier(insets: insets))
    }
}
