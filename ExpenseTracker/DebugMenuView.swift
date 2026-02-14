import SwiftUI
import SwiftData

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isWorking = false
    @State private var txCount: Int = 0
    @State private var budgetCount: Int = 0

    // Feedback alert
    @State private var showResultAlert = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""

    // Confirmation dialog (danger zone)
    enum DangerAction {
        case seedDuplicates
        case deleteTransactions
        case deleteBudgets
        case nukeEverything
    }
    @State private var showConfirm = false
    @State private var pendingDanger: DangerAction?

    var body: some View {
        NavigationStack {
            List {
                Section("Current Data") {
                    HStack {
                        Text("Transactions")
                        Spacer()
                        Text("\(txCount)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Budgets")
                        Spacer()
                        Text("\(budgetCount)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Seed") {
                    Button {
                        run {
                            let before = txCount
                            DebugSeeder.seedTransactions(modelContext: modelContext, allowDuplicates: false)
                            refreshCounts()
                            let added = max(0, txCount - before)
                            showResult(
                                title: "Seed complete",
                                message: added > 0
                                    ? "Added \(added) transactions."
                                    : "No transactions added (data already existed)."
                            )
                        }
                    } label: {
                        Label("Seed 12 months of transactions", systemImage: "wand.and.stars")
                    }
                    
                    Button {
                        pendingDanger = .seedDuplicates
                        showConfirm = true
                    } label: {
                        Label("Seed again (allow duplicates)", systemImage: "plus.square.on.square")
                    }

                    Button {
                        run {
                            DebugSeeder.seedBudgets(modelContext: modelContext)
                            refreshCounts()
                            showResult(title: "Seed complete", message: "Budgets seeded/updated for this month & year.")
                        }
                    } label: {
                        Label("Seed budgets (monthly + yearly)", systemImage: "target")
                    }
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        pendingDanger = .deleteTransactions
                        showConfirm = true
                    } label: {
                        Label("Delete ALL transactions", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        pendingDanger = .deleteBudgets
                        showConfirm = true
                    } label: {
                        Label("Delete ALL budgets", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        pendingDanger = .nukeEverything
                        showConfirm = true
                    } label: {
                        Label("NUKE EVERYTHING", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isWorking { ProgressView() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .disabled(isWorking)
            .onAppear { refreshCounts() }

            // ✅ result alert after any action
            .alert(resultTitle, isPresented: $showResultAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage)
            }

            // ✅ confirmation dialog for destructive actions
            .confirmationDialog(
                "Are you sure?",
                isPresented: $showConfirm,
                titleVisibility: .visible
            ) {
                Button(dangerButtonTitle(), role: .destructive) {
                    run { performDangerAction() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(dangerMessage())
            }
        }
    }

    // MARK: - Helpers

    private func run(_ work: () -> Void) {
        isWorking = true
        work()
        isWorking = false
    }

    private func refreshCounts() {
        do {
            txCount = try modelContext.fetchCount(FetchDescriptor<TransactionModel>())
            budgetCount = try modelContext.fetchCount(FetchDescriptor<BudgetModel>())
        } catch {
            showResult(title: "Error", message: "Failed to fetch counts: \(error)")
        }
    }

    private func showResult(title: String, message: String) {
        resultTitle = title
        resultMessage = message
        showResultAlert = true
    }

    private func dangerButtonTitle() -> String {
        switch pendingDanger {
        case .seedDuplicates: return "Seed duplicates"
        case .deleteTransactions: return "Delete transactions"
        case .deleteBudgets: return "Delete budgets"
        case .nukeEverything: return "Nuke everything"
        case .none: return "Confirm"
        }
    }

    private func dangerMessage() -> String {
        switch pendingDanger {
        case .seedDuplicates:
            return "This will add another batch of test transactions, even if you already have data."
        case .deleteTransactions:
            return "This will permanently delete all transactions from the app."
        case .deleteBudgets:
            return "This will permanently delete all saved budgets."
        case .nukeEverything:
            return "This will permanently delete ALL transactions and budgets."
        case .none:
            return ""
        }
    }

    private func performDangerAction() {
        guard let action = pendingDanger else { return }

        switch action {
        case .deleteTransactions:
            DebugSeeder.deleteAllTransactions(modelContext: modelContext)
            refreshCounts()
            showResult(title: "Done", message: "All transactions deleted.")
        case .deleteBudgets:
            DebugSeeder.deleteAllBudgets(modelContext: modelContext)
            refreshCounts()
            showResult(title: "Done", message: "All budgets deleted.")
        case .nukeEverything:
            DebugSeeder.deleteAllTransactions(modelContext: modelContext)
            DebugSeeder.deleteAllBudgets(modelContext: modelContext)
            refreshCounts()
            showResult(title: "Done", message: "Everything deleted.")
        case .seedDuplicates:
            let before = txCount
            DebugSeeder.seedTransactions(modelContext: modelContext, allowDuplicates: true)
            refreshCounts()
            let added = max(0, txCount - before)
            showResult(title: "Seed complete", message: "Added \(added) transactions (duplicates allowed).")
        }

        pendingDanger = nil
    }
}
