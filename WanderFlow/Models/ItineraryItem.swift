import Foundation
import SwiftData

@Model
final class ItineraryItem {
    var title: String
    var date: Date // Now includes time
    var note: String
    var placeName: String?
    var latitude: Double?
    var longitude: Double?
    
    // Add city info
    var cityName: String?
    var cityLatitude: Double?
    var cityLongitude: Double?
    
    init(title: String, date: Date, note: String = "", placeName: String? = nil, latitude: Double? = nil, longitude: Double? = nil, cityName: String? = nil, cityLatitude: Double? = nil, cityLongitude: Double? = nil) {
        self.title = title
        self.date = date
        self.note = note
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.cityLatitude = cityLatitude
        self.cityLongitude = cityLongitude
    }
}
