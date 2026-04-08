import SwiftUI

struct SearchResultRow: View {
    var title: String
    var subtitle: String?
    var trailingText: String?
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let trailingText, !trailingText.isEmpty {
                Text(trailingText)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .contentShape(Rectangle())
    }
}

