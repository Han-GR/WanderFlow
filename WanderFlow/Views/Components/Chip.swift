import SwiftUI

struct Chip: View {
    var text: String
    var systemImage: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(CuteTheme.gradient)
        .clipShape(Capsule())
    }
}

