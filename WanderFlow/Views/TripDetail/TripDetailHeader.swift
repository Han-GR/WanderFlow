import SwiftUI

struct TripDetailHeader: View {
    var trip: Trip
    var onEditDefaultCity: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(trip.title)
                    .font(AppTypography.pageTitle)
                Spacer()
                Image(systemName: trip.resolvedStyle.systemImage)
                    .foregroundColor(trip.resolvedStyle.accent)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(dateRangeText)
            }
            .font(AppTypography.caption)
            .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Chip(text: "行程 \(trip.itinerary.count)", systemImage: "list.bullet")
                Chip(text: "支出 \(trip.expenses.count)", systemImage: "creditcard")
            }
            
            Button {
                onEditDefaultCity?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(trip.resolvedStyle.accent)
                    Text("默认城市")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(trip.defaultCityName ?? "未设置")
                        .foregroundColor(trip.defaultCityName == nil ? .secondary : .primary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .font(AppTypography.body)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .disabled(onEditDefaultCity == nil)
        }
        .padding(14)
        .background(CuteTheme.cardBackground(cornerRadius: CuteTheme.headerCornerRadius))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    private var dateRangeText: String {
        guard let start = trip.startDate, let end = trip.endDate else {
            return "未设置日期"
        }
        return "\(start.formatted(date: .abbreviated, time: .omitted)) · \(end.formatted(date: .abbreviated, time: .omitted))"
    }
    
}
