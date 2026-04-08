import Foundation
import SwiftData

@Model
final class Trip {
    var title: String
    var createdAt: Date
    var startDate: Date?
    var endDate: Date?
    var coverColorHex: String?
    var styleRaw: String?
    
    var defaultCityName: String?
    var defaultCityLatitude: Double?
    var defaultCityLongitude: Double?
    var itinerary: [ItineraryItem]
    var expenses: [Expense]
    
    init(
        title: String,
        createdAt: Date = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil,
        coverColorHex: String? = nil,
        styleRaw: String? = nil,
        defaultCityName: String? = nil,
        defaultCityLatitude: Double? = nil,
        defaultCityLongitude: Double? = nil,
        itinerary: [ItineraryItem] = [],
        expenses: [Expense] = []
    ) {
        self.title = title
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.coverColorHex = coverColorHex
        self.styleRaw = styleRaw
        self.defaultCityName = defaultCityName
        self.defaultCityLatitude = defaultCityLatitude
        self.defaultCityLongitude = defaultCityLongitude
        self.itinerary = itinerary
        self.expenses = expenses
    }
}
