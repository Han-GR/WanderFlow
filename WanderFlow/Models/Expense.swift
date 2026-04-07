import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Double
    var currency: String
    var note: String
    var category: String
    var occurredAt: Date?
    var createdAt: Date
    
    var stayStartDate: Date?
    var nights: Int?
    
    init(
        amount: Double,
        currency: String = "CNY",
        note: String = "",
        category: String = "其他",
        occurredAt: Date? = nil,
        createdAt: Date = Date(),
        stayStartDate: Date? = nil,
        nights: Int? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.note = note
        self.category = category
        self.occurredAt = occurredAt
        self.createdAt = createdAt
        self.stayStartDate = stayStartDate
        self.nights = nights
    }
}
