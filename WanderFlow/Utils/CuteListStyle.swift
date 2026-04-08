import SwiftUI

extension View {
    func cuteListStyle() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(CuteTheme.background)
    }
}

