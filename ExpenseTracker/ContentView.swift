import SwiftUI
import SwiftData

struct ContentView: View {

    @Query(sort: \TransactionModel.date, order: .reverse)
    private var transactions: [TransactionModel]

    private var thisMonthTotal: Decimal {
        let startOfMonth = Calendar.current
            .dateInterval(of: .month, for: Date())!
            .start

        return transactions
            .filter { $0.date >= startOfMonth }
            .reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    private let categories: [Category] = CategoryCatalog.all

    @State private var selectedCategory: Category? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private func currency(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: ns) ?? "£0.00"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Month")
                        .font(.headline)

                    Text(currency(thisMonthTotal))
                        .font(.largeTitle)
                        .bold()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(categories) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            CategoryTile(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
        }
        .sheet(item: $selectedCategory) { category in
            AddTransactionView(category: category)
        }
    }
}

struct CategoryTile: View {
    let category: Category

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(category.name)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
