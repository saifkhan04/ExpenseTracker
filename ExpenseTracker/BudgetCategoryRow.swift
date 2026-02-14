import SwiftUI

struct BudgetCategoryRow: View {
    let categoryName: String
    let icon: String
    let used: Decimal
    let limit: Decimal

    var body: some View {
        let usedClamped = max(Decimal(0), used)
        let left = limit - usedClamped
        let isOverspent = left < 0

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(categoryName, systemImage: icon)
                    .font(.body)

                Spacer()

                Text("\(currency(usedClamped)) / \(currency(limit))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progressValue(used: usedClamped, limit: limit))
                .tint(isOverspent ? .red : .blue)

            HStack {
                Text(isOverspent ? "Overspent" : "Left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currency(isOverspent ? -left : left))
                    .font(.caption)
                    .bold()
                    .foregroundStyle(isOverspent ? .red : .secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func progressValue(used: Decimal, limit: Decimal) -> Double {
        guard limit > 0 else { return 0 }
        let ratio = (used as NSDecimalNumber).doubleValue / (limit as NSDecimalNumber).doubleValue
        return min(max(ratio, 0), 1)
    }

    private func currency(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: ns) ?? "£0.00"
    }
}
