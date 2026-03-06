import Foundation
import SwiftData

@Model
final class ItineraryItem {
    var title: String
    var date: Date
    var note: String
    var placeName: String?
    var latitude: Double?
    var longitude: Double?
    
    init(title: String, date: Date, note: String = "", placeName: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.title = title
        self.date = date
        self.note = note
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
    }
}
