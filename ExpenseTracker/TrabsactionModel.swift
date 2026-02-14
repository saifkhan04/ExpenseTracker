import Foundation
import SwiftData

@Model
final class TransactionModel {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var date: Date
    var signedAmount: Decimal

    var categoryId: String
    var categoryName: String

    var subcategoryName: String?
    var note: String?

    init(date: Date,
         signedAmount: Decimal,
         categoryId: String,
         categoryName: String,
         subcategoryName: String? = nil,
         note: String? = nil)
    {
        self.id = UUID()
        self.createdAt = Date()
        self.date = date
        self.signedAmount = signedAmount
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.subcategoryName = subcategoryName
        self.note = note
    }
}
