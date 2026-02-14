import SwiftUI
import SwiftData

enum EntryKind: String, CaseIterable {
    case expense = "Expense"
    case refund = "Refund"
}

struct AddTransactionView: View {
    let category: Category

    enum Field: Hashable { case amount, note }
    @FocusState private var focusedField: Field?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var kind: EntryKind = .expense
    @State private var amountText: String = ""
    @State private var selectedSubcategory: String? = nil
    @State private var note: String = ""
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Text(category.name)
                }

                Section("Type") {
                    Picker("Type", selection: $kind) {
                        ForEach(EntryKind.allCases, id: \.self) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Amount") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                }

                Section("Subcategory (optional)") {
                    Picker("Subcategory", selection: $selectedSubcategory) {
                        Text("None").tag(String?.none)
                        ForEach(category.subcategories, id: \.self) { sub in
                            Text(sub).tag(String?.some(sub))
                        }
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Note (optional)") {
                    TextField("e.g. Tesco offer applied", text: $note)
                        .focused($focusedField, equals: .note)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add \(category.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isAmountValid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear { focusedField = .amount }
        }
    }

    private var isAmountValid: Bool { parseAmount() != nil }

    private func parseAmount() -> Decimal? {
        let cleaned = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned)
    }
    
    private func save() {
        guard let amount = parseAmount(), amount > 0 else { return }
        let signedAmount = (kind == .expense) ? amount : -amount

        let tx = TransactionModel(
            date: date,
            signedAmount: signedAmount,
            categoryId: category.id,
            categoryName: category.name,
            subcategoryName: selectedSubcategory,
            note: note.isEmpty ? nil : note
        )

        modelContext.insert(tx)

        do {
            try modelContext.save()
            print("✅ Saved tx:", tx.categoryName, tx.signedAmount, tx.date)
        } catch {
            print("❌ SwiftData save failed:", error)
        }

        dismiss()
    }
}
