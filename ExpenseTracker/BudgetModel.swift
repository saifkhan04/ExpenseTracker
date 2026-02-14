import Foundation
import SwiftData

enum BudgetPeriod: String, Codable, CaseIterable {
    case monthly
    case yearly
}

@Model
final class BudgetModel {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var categoryId: String
    var period: BudgetPeriod

    /// Start of month/year (still useful for display/debug)
    var periodStart: Date

    /// YYYYMM for monthly, YYYY for yearly
    var periodKey: Int

    var limit: Decimal

    init(categoryId: String, period: BudgetPeriod, periodStart: Date, limit: Decimal) {
        self.id = UUID()
        self.createdAt = Date()
        self.categoryId = categoryId
        self.period = period
        self.periodStart = periodStart
        self.periodKey = BudgetModel.makePeriodKey(period: period, date: periodStart)
        self.limit = limit
    }

    static func makePeriodKey(period: BudgetPeriod, date: Date) -> Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: date)

        switch period {
        case .monthly:
            let month = cal.component(.month, from: date)
            return year * 100 + month   // e.g. 202602
        case .yearly:
            return year                 // e.g. 2026
        }
    }
}
