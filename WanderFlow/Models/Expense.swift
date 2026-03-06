import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Double
    var currency: String
    var note: String
    var createdAt: Date
    
    init(amount: Double, currency: String = "CNY", note: String = "", createdAt: Date = Date()) {
        self.amount = amount
        self.currency = currency
        self.note = note
        self.createdAt = createdAt
    }
}
