import Foundation
import SwiftData

@Model
final class Trip {
    var title: String
    var createdAt: Date
    var startDate: Date?
    var endDate: Date?
    var coverColorHex: String?
    var itinerary: [ItineraryItem]
    var expenses: [Expense]
    
    init(title: String, createdAt: Date = Date(), startDate: Date? = nil, endDate: Date? = nil, coverColorHex: String? = nil, itinerary: [ItineraryItem] = [], expenses: [Expense] = []) {
        self.title = title
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.coverColorHex = coverColorHex
        self.itinerary = itinerary
        self.expenses = expenses
    }
}
