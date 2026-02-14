import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    enum RangeOption: Int, CaseIterable, Identifiable {
        case last3 = 3
        case last6 = 6
        case last12 = 12

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .last3: return "3M"
            case .last6: return "6M"
            case .last12: return "12M"
            }
        }
    }

    struct MonthPoint: Identifiable {
        let id: String
        let monthStart: Date
        let netSpend: Decimal   // expenses - refunds
    }

    @State private var range: RangeOption = .last6

    @Query(sort: \TransactionModel.date, order: .forward)
    private var transactions: [TransactionModel]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $range) {
                        ForEach(RangeOption.allCases) { opt in
                            Text(opt.title).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowSeparator(.hidden)

                Section {
                    let points = monthSeries(monthsBack: range.rawValue)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Spending Trend")
                                .font(.headline)
                            Spacer()
                            Text(currency(total(points)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Chart(points) { p in
                            BarMark(
                                x: .value("Month", p.monthStart, unit: .month),
                                y: .value("Net Spend", ns(p.netSpend))
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 220)

                        Text("Net spend = expenses − refunds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Insights")
        }
    }

    // MARK: - Data

    private func monthSeries(monthsBack: Int) -> [MonthPoint] {
        let cal = Calendar.current
        let now = Date()
        let thisMonthStart = cal.dateInterval(of: .month, for: now)!.start

        // Build month starts: oldest -> newest (e.g. 6 months includes current month)
        let monthStarts: [Date] = (0..<monthsBack)
            .compactMap { offset in
                cal.date(byAdding: .month, value: -(monthsBack - 1 - offset), to: thisMonthStart)
            }

        // Bucket sums by YYYYMM key
        var sums: [Int: Decimal] = [:]
        for tx in transactions {
            let key = yearMonthKey(tx.date)
            sums[key, default: 0] += tx.signedAmount
        }

        return monthStarts.map { mStart in
            let key = yearMonthKey(mStart)
            let net = sums[key] ?? 0
            return MonthPoint(
                id: "\(key)",
                monthStart: mStart,
                netSpend: max(0, net) // don’t show negative bars
            )
        }
    }

    private func yearMonthKey(_ date: Date) -> Int {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return y * 100 + m
    }

    private func total(_ points: [MonthPoint]) -> Decimal {
        points.reduce(Decimal(0)) { $0 + $1.netSpend }
    }

    // MARK: - Formatting

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: value as NSDecimalNumber) ?? "£0.00"
    }

    private func ns(_ value: Decimal) -> Double {
        (value as NSDecimalNumber).doubleValue
    }
}
