import SwiftUI

struct Chip: View {
    var text: String
    var systemImage: String
    var background: AnyShapeStyle = AnyShapeStyle(CuteTheme.gradient)
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(AppTypography.captionEmphasis)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(background)
        .clipShape(Capsule())
    }
}
