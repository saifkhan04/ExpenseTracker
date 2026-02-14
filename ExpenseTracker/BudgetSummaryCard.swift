import SwiftUI

struct BudgetSummaryCard: View {
    let title: String
    let used: Decimal
    let limit: Decimal

    var body: some View {
        let usedClamped = max(Decimal(0), used)                 // don’t go negative
        let progress = progressValue(used: usedClamped, limit: limit)
        let left = limit - usedClamped
        let isOverspent = left < 0

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(percentText(used: usedClamped, limit: limit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(currency(usedClamped))
                    .font(.title2)
                    .bold()
                Text(" / \(currency(limit))")
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ProgressView(value: progress)
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
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func progressValue(used: Decimal, limit: Decimal) -> Double {
        guard limit > 0 else { return 0 }
        let ratio = (used as NSDecimalNumber).doubleValue / (limit as NSDecimalNumber).doubleValue
        return min(max(ratio, 0), 1)
    }

    private func percentText(used: Decimal, limit: Decimal) -> String {
        guard limit > 0 else { return "—" }
        let ratio = (used as NSDecimalNumber).doubleValue / (limit as NSDecimalNumber).doubleValue
        return "\(Int(round(ratio * 100)))%"
    }

    private func currency(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: ns) ?? "£0.00"
    }
}
