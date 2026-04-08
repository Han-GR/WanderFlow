import SwiftUI

struct TripDetailMenuRow: View {
    var title: String
    var systemImage: String
    var isDestructive: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(CuteTheme.gradient)
                        .frame(width: 36, height: 36)
                        .opacity(isDestructive ? 0.6 : 1.0)
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isDestructive ? .red : CuteTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDestructive ? .red : .primary)
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(CuteTheme.cardBackground(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

