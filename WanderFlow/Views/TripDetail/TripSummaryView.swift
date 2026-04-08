import SwiftUI

struct TripSummaryView: View {
    var trip: Trip
    
    private let calendar = Calendar.current
    
    var body: some View {
        List {
            Section("按币种总计") {
                ForEach(currencyTotals, id: \.0) { currency, total in
                    HStack {
                        Text(currency)
                        Spacer()
                        Text(total, format: .currency(code: currency))
                            .monospacedDigit()
                    }
                }
            }
            
            Section("按天总计") {
                ForEach(dailyTotals, id: \.day) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.day, format: .dateTime.weekday().month().day())
                            .font(.headline)
                        ForEach(row.totals, id: \.0) { currency, total in
                            HStack {
                                Text(currency)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(total, format: .currency(code: currency))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .font(.subheadline)
                        }
                    }
                    .listCard(insets: EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(CuteTheme.background)
    }
    
    private var currencyTotals: [(String, Double)] {
        let totals = trip.expenses.reduce(into: [String: Double]()) { dict, exp in
            dict[exp.currency, default: 0] += exp.amount
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    private var dailyTotals: [DailyTotalRow] {
        let dayTotals = expensesExpandedToDays().reduce(into: [Date: [String: Double]]()) { dict, item in
            let day = item.day
            var byCurrency = dict[day, default: [:]]
            byCurrency[item.currency, default: 0] += item.amount
            dict[day] = byCurrency
        }
        
        return dayTotals
            .map { day, map in
                DailyTotalRow(
                    day: day,
                    totals: map.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
                )
            }
            .sorted { $0.day < $1.day }
    }
    
    private func expensesExpandedToDays() -> [DailyExpense] {
        var result: [DailyExpense] = []
        
        for exp in trip.expenses {
            if exp.category == "住宿", let start = exp.stayStartDate, let nights = exp.nights, nights > 0 {
                let perNight = exp.amount / Double(nights)
                for offset in 0..<nights {
                    if let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: start)) {
                        result.append(DailyExpense(day: day, currency: exp.currency, amount: perNight))
                    }
                }
            } else {
                let date = exp.occurredAt ?? exp.createdAt
                let day = calendar.startOfDay(for: date)
                result.append(DailyExpense(day: day, currency: exp.currency, amount: exp.amount))
            }
        }
        
        return result
    }
}

private struct DailyTotalRow {
    let day: Date
    let totals: [(String, Double)]
}

private struct DailyExpense {
    let day: Date
    let currency: String
    let amount: Double
}
