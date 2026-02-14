import SwiftUI
import SwiftData

struct BudgetEditView: View {
    let category: Category
    let period: BudgetPeriod

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amountText: String = ""

    private var periodStart: Date {
        switch period {
        case .monthly: return Calendar.current.dateInterval(of: .month, for: Date())!.start
        case .yearly:  return Calendar.current.dateInterval(of: .year, for: Date())!.start
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Label(category.name, systemImage: category.icon)
                }

                Section(period == .monthly ? "Monthly budget" : "Yearly budget") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(parseAmount() == nil)
                }
            }
            .onAppear {
                // Prefill existing value if present
                if let existing = fetchExisting() {
                    amountText = "\(existing.limit)"
                } else {
                    amountText = ""
                }
            }
        }
    }

    private func parseAmount() -> Decimal? {
        let cleaned = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned)
    }
    
    private var periodKey: Int {
        BudgetModel.makePeriodKey(period: period, date: Date())
    }

    private func fetchExisting() -> BudgetModel? {
        let catId = category.id
        let key = BudgetModel.makePeriodKey(period: period, date: periodStart)

        let descriptor = FetchDescriptor<BudgetModel>(
            predicate: #Predicate { b in
                b.categoryId == catId && b.periodKey == key
            }
        )

        let matches = (try? modelContext.fetch(descriptor)) ?? []
        return matches.first(where: { $0.period == period })
    }

    private func save() {
        guard let amount = parseAmount(), amount >= 0 else { return }

        if let existing = fetchExisting() {
            existing.limit = amount
            existing.periodStart = periodStart
            existing.periodKey = BudgetModel.makePeriodKey(period: period, date: periodStart)
        } else {
            let b = BudgetModel(categoryId: category.id, period: period, periodStart: periodStart, limit: amount)
            modelContext.insert(b)
        }

        do { try modelContext.save() } catch { print("Budget save failed:", error) }
        dismiss()
    }
}
