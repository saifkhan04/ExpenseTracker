import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

#if DEBUG
    @State private var showDebugPasscode = false
    @State private var showDebugMenu = false
    private let debugPasscode = "0410"
#endif
    
    var body: some View {
        TabView {
            NavigationStack { ContentView() }
                .tabItem { Label("Home", systemImage: "square.grid.2x2") }

            NavigationStack { LedgerView() }
                .tabItem { Label("Ledger", systemImage: "list.bullet") }

            NavigationStack { BudgetsView() }
                .tabItem { Label("Budgets", systemImage: "target") }

            NavigationStack { InsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.bar") }
        }
#if DEBUG
    .contentShape(Rectangle())
    .onTapGesture(count: 3) {
        showDebugPasscode = true
    }
    .sheet(isPresented: $showDebugPasscode) {
        DebugPasscodeView(expected: debugPasscode) {
            showDebugMenu = true
        }
    }
    .sheet(isPresented: $showDebugMenu) {
        DebugMenuView()
    }
#endif
    }
}
