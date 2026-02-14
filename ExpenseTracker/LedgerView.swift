import SwiftUI
import SwiftData

struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TransactionModel.date, order: .reverse)
    private var transactions: [TransactionModel]

    @State private var editingTx: TransactionModel?

    // nil = All
    @State private var selectedMonthStart: Date? = nil

    // Search (all-time)
    @State private var searchText: String = ""

    // Animation direction for month navigation
    @State private var navDirection: Int = 0 // -1 newer, +1 older

    var body: some View {
        List {
            Section {
                // If searching: show result summary
                if isSearching {
                    searchSummaryCard
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                } else if selectedMonthStart != nil {
                    monthSummaryCard
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                } else {
                    allTimeSummaryRow
                }

                filterMenuRow
                    .listRowSeparator(.hidden)

                // Month navigator only when a month filter is active AND not searching
                if !isSearching, selectedMonthStart != nil {
                    monthNavigatorRow
                        .listRowSeparator(.hidden)
                }
            }

            Group {
                if displayedSections.isEmpty {
                    ContentUnavailableView(
                        isSearching ? "No results" : "No transactions",
                        systemImage: "tray",
                        description: Text(isSearching ? "Try a different search." : "Add a transaction to see it here.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(displayedSections, id: \.monthStart) { section in
                        Section {
                            ForEach(section.items) { tx in
                                row(tx)
                            }
                            .onDelete { indexSet in
                                delete(indexSet, in: section.items)
                            }
                        } header: {
                            HStack {
                                Text(section.title)
                                Spacer()
                                Text(currency(section.subtotal))
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
                        }
                    }
                }
            }
            .id(animatedContentID)
            .transition(contentTransition)
            .animation(.easeInOut(duration: 0.25), value: animatedContentID)
        }
        .navigationTitle("Ledger")
        .toolbar { EditButton() }
        .sheet(item: $editingTx) { tx in
            EditTransactionView(tx: tx)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search category, note, amount…")
        .onChange(of: searchText) { _, newValue in
            // When searching, force global mode (All months)
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                selectedMonthStart = nil
                navDirection = 0
            }
        }
        // Swipe left/right month navigation only when NOT searching and month filter active
        .highPriorityGesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard !isSearching, selectedMonthStart != nil else { return }

                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }

                    if dx < -35 {       // swipe left -> older month
                        goToOlderMonth()
                    } else if dx > 35 { // swipe right -> newer month
                        goToNewerMonth()
                    }
                }
        )
    }

    // MARK: - Top UI

    private var allTimeSummaryRow: some View {
        HStack {
            Text("All-time total")
            Spacer()
            Text(currency(allTimeTotal)).bold()
        }
    }

    private var monthSummaryCard: some View {
        let title = selectedMonthTitle
        let subtotal = selectedMonthSubtotal

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("Month total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(currency(subtotal))
                .font(.title2)
                .bold()

            Text("Tip: swipe left/right to change month")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var searchSummaryCard: some View {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let total = searchTotal
        let count = searchedTransactions.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Results")
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("“\(q)”")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currency(total))
                    .font(.headline)
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var filterMenuRow: some View {
        Menu {
            Button("All") {
                withAnimation(.easeInOut) {
                    selectedMonthStart = nil
                    navDirection = 0
                }
            }

            Divider()

            ForEach(allMonthStarts, id: \.self) { mStart in
                let title = mStart.formatted(.dateTime.year().month())
                let subtotal = monthSubtotal(for: mStart)

                Button("\(title) — \(currency(subtotal))") {
                    withAnimation(.easeInOut) {
                        selectedMonthStart = mStart
                        navDirection = 0
                    }
                }
            }
        } label: {
            HStack {
                Label("Filter", systemImage: "calendar")
                Spacer()
                Text(isSearching ? "All (searching)" : (selectedMonthStart == nil ? "All" : selectedMonthTitle))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var monthNavigatorRow: some View {
        HStack(spacing: 12) {
            Button { goToNewerMonth() } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .disabled(!canGoNewer)

            Button {
                withAnimation(.easeInOut) {
                    selectedMonthStart = nil
                    navDirection = 0
                }
            } label: {
                Text("All").font(.subheadline)
            }

            Spacer()

            Button { goToOlderMonth() } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
            .disabled(!canGoOlder)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    // MARK: - Search

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var searchedTransactions: [TransactionModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        return transactions.filter { matches($0, query: q) }
    }

    private func matches(_ tx: TransactionModel, query: String) -> Bool {
        let q = query.lowercased()

        if tx.categoryName.lowercased().contains(q) { return true }
        if tx.categoryId.lowercased().contains(q) { return true }
        if (tx.subcategoryName ?? "").lowercased().contains(q) { return true }
        if (tx.note ?? "").lowercased().contains(q) { return true }

        // Amount search: allow "12.5", "-20", "300"
        let amountString = "\(tx.signedAmount)".lowercased()
        if amountString.contains(q) { return true }

        // Also allow searching by formatted date text (optional)
        let dateString = tx.date.formatted(date: .abbreviated, time: .omitted).lowercased()
        if dateString.contains(q) { return true }

        return false
    }

    private var searchTotal: Decimal {
        searchedTransactions.reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    // MARK: - Animated content helpers

    private var animatedContentID: String {
        if isSearching {
            return "search-\(searchText.lowercased())"
        }
        if let m = selectedMonthStart {
            return "month-\(yearMonthKey(m))"
        }
        return "all"
    }

    private var contentTransition: AnyTransition {
        if isSearching { return .opacity }
        guard selectedMonthStart != nil else { return .opacity }

        if navDirection >= 0 {
            return .move(edge: .trailing).combined(with: .opacity)
        } else {
            return .move(edge: .leading).combined(with: .opacity)
        }
    }

    // MARK: - Row UI

    private func row(_ tx: TransactionModel) -> some View {
        Button {
            editingTx = tx
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tx.categoryName).font(.headline)
                    Spacer()
                    Text(currency(tx.signedAmount)).font(.headline)
                }

                HStack(spacing: 8) {
                    if let sub = tx.subcategoryName, !sub.isEmpty {
                        Text(sub).foregroundStyle(.secondary)
                    }
                    Text(tx.date.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)

                if let note = tx.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button { editingTx = tx } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { deleteById(tx) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: - Grouping / Filtering (All-time + month filter + search)

    private struct MonthSection {
        let monthStart: Date
        let title: String
        let items: [TransactionModel]
        let subtotal: Decimal
    }

    private var allMonthStarts: [Date] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: transactions) { tx in
            cal.dateInterval(of: .month, for: tx.date)!.start
        }
        return groups.keys.sorted(by: >)
    }

    private var selectedMonthTitle: String {
        guard let selectedMonthStart else { return "All" }
        return selectedMonthStart.formatted(.dateTime.year().month())
    }

    private var selectedMonthSubtotal: Decimal {
        guard let selectedMonthStart else { return 0 }
        return monthSubtotal(for: selectedMonthStart)
    }

    private var displayedSections: [MonthSection] {
        // If searching: ignore month filter and group searched results across all months
        if isSearching {
            return makeSections(from: searchedTransactions)
        }

        // Not searching: if month selected, show only that month; else show all
        if let selectedMonthStart {
            let cal = Calendar.current
            let interval = cal.dateInterval(of: .month, for: selectedMonthStart)!
            let start = interval.start
            let end = interval.end

            let monthItems = transactions.filter { $0.date >= start && $0.date < end }
            return makeSections(from: monthItems)
        }

        return makeSections(from: transactions)
    }

    private func makeSections(from list: [TransactionModel]) -> [MonthSection] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: list) { tx in
            cal.dateInterval(of: .month, for: tx.date)!.start
        }

        let sortedMonthStarts = groups.keys.sorted(by: >)

        return sortedMonthStarts.map { mStart in
            let items = groups[mStart] ?? []
            let subtotal = items.reduce(Decimal(0)) { $0 + $1.signedAmount }
            return MonthSection(
                monthStart: mStart,
                title: mStart.formatted(.dateTime.year().month()),
                items: items,
                subtotal: subtotal
            )
        }
    }

    private func monthSubtotal(for monthStart: Date) -> Decimal {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .month, for: monthStart)!
        let start = interval.start
        let end = interval.end

        return transactions
            .filter { $0.date >= start && $0.date < end }
            .reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    private func yearMonthKey(_ date: Date) -> Int {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return y * 100 + m
    }

    // MARK: - Month navigation

    private var selectedIndex: Int? {
        guard let selectedMonthStart else { return nil }
        return allMonthStarts.firstIndex(of: selectedMonthStart)
    }

    private var canGoOlder: Bool {
        guard let i = selectedIndex else { return false }
        return i < allMonthStarts.count - 1
    }

    private var canGoNewer: Bool {
        guard let i = selectedIndex else { return false }
        return i > 0
    }

    private func goToOlderMonth() {
        guard let i = selectedIndex, i < allMonthStarts.count - 1 else { return }
        navDirection = +1
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedMonthStart = allMonthStarts[i + 1]
        }
    }

    private func goToNewerMonth() {
        guard let i = selectedIndex, i > 0 else { return }
        navDirection = -1
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedMonthStart = allMonthStarts[i - 1]
        }
    }

    // MARK: - Totals & Formatting

    private var allTimeTotal: Decimal {
        transactions.reduce(Decimal(0)) { $0 + $1.signedAmount }
    }

    private func currency(_ value: Decimal) -> String {
        let ns = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: ns) ?? "£0.00"
    }

    // MARK: - Delete

    private func delete(_ indexSet: IndexSet, in items: [TransactionModel]) {
        for index in indexSet {
            modelContext.delete(items[index])
        }
        do { try modelContext.save() } catch { print("Delete save failed:", error) }
    }

    private func deleteById(_ tx: TransactionModel) {
        modelContext.delete(tx)
        do { try modelContext.save() } catch { print("Delete save failed:", error) }
    }
}
