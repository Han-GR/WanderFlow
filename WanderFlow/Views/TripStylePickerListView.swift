import SwiftUI

struct TripStylePickerListView: View {
    @Binding var selection: TripStyle
    @Binding var isPresented: Bool
    
    var body: some View {
        List {
            ForEach(TripStyle.allCases) { style in
                Button {
                    selection = style
                    isPresented = false
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(style.gradient)
                                .frame(width: 28, height: 28)
                            Image(systemName: style.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(style.accent)
                        }
                        
                        Text(style.title)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Spacer()
                        
                        if style == selection {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(style.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("home.newTrip.field.style")
        .navigationBarTitleDisplayMode(.inline)
        .cuteListStyle()
    }
}

