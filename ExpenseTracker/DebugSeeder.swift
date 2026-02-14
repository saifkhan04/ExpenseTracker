import Foundation
import SwiftData

enum DebugSeeder {
    static func seedTransactions(modelContext: ModelContext, allowDuplicates: Bool) {
        if !allowDuplicates {
            let existing = (try? modelContext.fetch(FetchDescriptor<TransactionModel>())) ?? []
            if !existing.isEmpty { return }
        }

        let cal = Calendar.current
        let now = Date()

        func addTx(monthOffset: Int, day: Int, category: Category, sub: String?, amount: Decimal) {
            let monthDate = cal.date(byAdding: .month, value: -monthOffset, to: now)!
            let date = cal.date(from: DateComponents(
                year: cal.component(.year, from: monthDate),
                month: cal.component(.month, from: monthDate),
                day: min(day, 28),
                hour: 18,
                minute: 30
            ))!

            let tx = TransactionModel(
                date: date,
                signedAmount: amount,
                categoryId: category.id,
                categoryName: category.name,
                subcategoryName: sub,
                note: "Seed data"
            )
            modelContext.insert(tx)
        }

        let groceries = CategoryCatalog.byId("Groceries")!
        let eatingOut = CategoryCatalog.byId("Eating Out")!
        let transport = CategoryCatalog.byId("Transport")!
        let selfCare = CategoryCatalog.byId("Self Care")!

        let shopping = CategoryCatalog.byId("Shopping")!
        let gifts = CategoryCatalog.byId("Gifts")!
        let trips = CategoryCatalog.byId("Trips")!
        let electronics = CategoryCatalog.byId("Electronics")!

        for m in 0..<12 {
            addTx(monthOffset: m, day: 5,  category: groceries, sub: "Supermarket", amount: Decimal(120 + (m * 5)))
            addTx(monthOffset: m, day: 10, category: eatingOut, sub: "Dinner",     amount: Decimal(60 + (m * 3)))
            addTx(monthOffset: m, day: 15, category: transport, sub: "Train",      amount: Decimal(80 + (m * 2)))
            addTx(monthOffset: m, day: 18, category: selfCare,  sub: "Skincare",   amount: Decimal(25 + (m % 4) * 5))

            if m % 3 == 0 { addTx(monthOffset: m, day: 20, category: shopping, sub: "Clothes", amount: Decimal(150 + (m * 2))) }
            if m % 4 == 0 { addTx(monthOffset: m, day: 22, category: gifts, sub: "Birthday", amount: Decimal(50)) }
            if m == 1 || m == 6 || m == 10 { addTx(monthOffset: m, day: 25, category: trips, sub: "Hotel", amount: Decimal(300)) }
            if m % 6 == 0 { addTx(monthOffset: m, day: 26, category: electronics, sub: "Gadgets", amount: Decimal(200)) }

            if m % 5 == 0 { addTx(monthOffset: m, day: 27, category: groceries, sub: "Supermarket", amount: Decimal(-20)) }
        }

        do { try modelContext.save() } catch { print("Seed tx save failed:", error) }
    }

    static func seedBudgets(modelContext: ModelContext) {
        // Current period keys
        let monthStart = Calendar.current.dateInterval(of: .month, for: Date())!.start
        let yearStart = Calendar.current.dateInterval(of: .year, for: Date())!.start

        func upsertBudget(categoryId: String, period: BudgetPeriod, start: Date, limit: Decimal) {
            let key = BudgetModel.makePeriodKey(period: period, date: start)

            let descriptor = FetchDescriptor<BudgetModel>(
                predicate: #Predicate { b in
                    b.categoryId == categoryId && b.periodKey == key
                }
            )

            let matches = (try? modelContext.fetch(descriptor)) ?? []
            if let existing = matches.first(where: { $0.period == period }) {
                existing.limit = limit
                existing.periodStart = start
                existing.periodKey = key
            } else {
                let b = BudgetModel(categoryId: categoryId, period: period, periodStart: start, limit: limit)
                modelContext.insert(b)
            }
        }

        // Monthly budgets
        upsertBudget(categoryId: "Groceries", period: .monthly, start: monthStart, limit: 400)
        upsertBudget(categoryId: "Eating Out", period: .monthly, start: monthStart, limit: 250)
        upsertBudget(categoryId: "Transport", period: .monthly, start: monthStart, limit: 180)
        upsertBudget(categoryId: "Self Care", period: .monthly, start: monthStart, limit: 120)

        // Yearly budgets
        upsertBudget(categoryId: "Shopping", period: .yearly, start: yearStart, limit: 1500)
        upsertBudget(categoryId: "Trips", period: .yearly, start: yearStart, limit: 2000)
        upsertBudget(categoryId: "Electronics", period: .yearly, start: yearStart, limit: 800)
        upsertBudget(categoryId: "Gifts", period: .yearly, start: yearStart, limit: 500)

        do { try modelContext.save() } catch { print("Seed budgets save failed:", error) }
    }

    static func deleteAllTransactions(modelContext: ModelContext) {
        do {
            let all = try modelContext.fetch(FetchDescriptor<TransactionModel>())
            for tx in all { modelContext.delete(tx) }
            try modelContext.save()
        } catch {
            print("Delete all transactions failed:", error)
        }
    }

    static func deleteAllBudgets(modelContext: ModelContext) {
        do {
            let all = try modelContext.fetch(FetchDescriptor<BudgetModel>())
            for b in all { modelContext.delete(b) }
            try modelContext.save()
        } catch {
            print("Delete all budgets failed:", error)
        }
    }
}
