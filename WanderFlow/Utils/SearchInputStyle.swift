import SwiftUI

extension View {
    func searchInputStyle() -> some View {
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
    }
}

