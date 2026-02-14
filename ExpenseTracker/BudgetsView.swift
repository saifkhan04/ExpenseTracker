import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [BudgetModel]
    @Query(sort: \TransactionModel.date)
    private var transactions: [TransactionModel]

    @State private var editingCategory: Category?
    @State private var editingPeriod: BudgetPeriod = .monthly
    @State private var mode: BudgetPeriod = .monthly

    private let monthStart = Calendar.current.dateInterval(of: .month, for: Date())!.start
    private let yearStart = Calendar.current.dateInterval(of: .year, for: Date())!.start
    private var currentMonthKey: Int { BudgetModel.makePeriodKey(period: .monthly, date: Date()) }
    private var currentYearKey: Int { BudgetModel.makePeriodKey(period: .yearly, date: Date()) }

    var body: some View {
        NavigationStack {
            Section {
                Picker("Mode", selection: $mode) {
                    Text("Monthly").tag(BudgetPeriod.monthly)
                    Text("Yearly").tag(BudgetPeriod.yearly)
                }
                .pickerStyle(.segmented)
            }
            .listRowSeparator(.hidden)
            List {
                Section {
                    if mode == .monthly {
                        BudgetSummaryCard(title: "This Month", used: totalMonthlyUsed, limit: monthlyTotal)
                    } else {
                        BudgetSummaryCard(title: "This Year", used: totalYearlyUsed, limit: yearlyTotal)
                    }
                }
                .listRowSeparator(.hidden)
                Section(mode == .monthly ? "Monthly budgets" : "Yearly budgets") {
                    let filtered = CategoryCatalog.all.filter { $0.tracking == (mode == .monthly ? .monthly : .yearly) }

                    ForEach(filtered) { cat in
                        Button {
                            editingCategory = cat
                            editingPeriod = mode
                        } label: {
                            let limit = limitFor(cat, mode)
                            let used = spendingFor(cat, mode)

                            BudgetCategoryRow(
                                categoryName: cat.name,
                                icon: cat.icon,
                                used: used,
                                limit: limit
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Budgets")
            .sheet(item: $editingCategory) { cat in
                BudgetEditView(category: cat, period: editingPeriod)
            }
        }
    }

    private var monthlyTotal: Decimal {
        let key = BudgetModel.makePeriodKey(period: .monthly, date: Date())
        return budgets
            .filter { $0.periodKey == key }
            .filter { $0.period == .monthly }
            .reduce(Decimal(0)) { $0 + $1.limit }
    }

    private var yearlyTotal: Decimal {
        let key = BudgetModel.makePeriodKey(period: .yearly, date: Date())
        return budgets
            .filter { $0.periodKey == key }
            .filter { $0.period == .yearly }
            .reduce(Decimal(0)) { $0 + $1.limit }
    }
    
    private func limitFor(_ category: Category, _ period: BudgetPeriod) -> Decimal {
        let key = BudgetModel.makePeriodKey(period: period, date: Date())

        return budgets
            .filter { $0.categoryId == category.id && $0.periodKey == key }
            .first(where: { $0.period == period })?
            .limit ?? 0
    }
    
    private var totalMonthlyUsed: Decimal {
        let interval = Calendar.current.dateInterval(of: .month, for: Date())!
        let monthlyIds = Set(CategoryCatalog.all.filter { $0.tracking == .monthly }.map { $0.id })

        return transactions
            .filter {
                monthlyIds.contains($0.categoryId) &&
                $0.date >= interval.start && $0.date < interval.end
            }
            .reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    private var totalYearlyUsed: Decimal {
        let interval = Calendar.current.dateInterval(of: .year, for: Date())!
        let yearlyIds = Set(CategoryCatalog.all.filter { $0.tracking == .yearly }.map { $0.id })

        return transactions
            .filter {
                yearlyIds.contains($0.categoryId) &&
                $0.date >= interval.start && $0.date < interval.end
            }
            .reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }

    private func currency(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: ns) ?? "£0.00"
    }
    
    private func spendingFor(_ category: Category, _ period: BudgetPeriod) -> Decimal {
        let interval: DateInterval

        switch period {
        case .monthly:
            interval = Calendar.current.dateInterval(of: .month, for: Date())!
        case .yearly:
            interval = Calendar.current.dateInterval(of: .year, for: Date())!
        }

        return transactions
            .filter {
                $0.categoryId == category.id &&
                $0.date >= interval.start &&
                $0.date < interval.end
            }
            .reduce(Decimal(0)) { $0 + $1.signedAmount }
    }
}
