import SwiftUI

struct ListCardModifier: ViewModifier {
    var insets: EdgeInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
    
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
    func listCard(insets: EdgeInsets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)) -> some View {
        modifier(ListCardModifier(insets: insets))
    }
}

