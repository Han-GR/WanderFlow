import SwiftUI

struct CardMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let isDestructive: Bool
    let action: () -> Void
}

struct CardMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var items: [CardMenuItem]
    
    var body: some View {
        VStack(spacing: 12) {
            Color.clear.frame(height: 0)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            VStack(spacing: 10) {
                ForEach(items) { item in
                    TripDetailMenuRow(title: item.title, systemImage: item.systemImage, isDestructive: item.isDestructive) {
                        dismiss()
                        DispatchQueue.main.async { item.action() }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
