import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Bindable var tx: TransactionModel

    enum Field: Hashable { case amount, note }
    @FocusState private var focusedField: Field?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var kind: EntryKind
    @State private var amountText: String

    @State private var selectedCategoryId: String
    @State private var selectedSubcategory: String?

    init(tx: TransactionModel) {
        self.tx = tx

        // kind + amount
        let isRefund = (tx.signedAmount < 0)
        _kind = State(initialValue: isRefund ? .refund : .expense)

        let absAmount = (tx.signedAmount < 0) ? -tx.signedAmount : tx.signedAmount
        _amountText = State(initialValue: "\(absAmount)")

        // category + subcategory
        _selectedCategoryId = State(initialValue: tx.categoryId)
        _selectedSubcategory = State(initialValue: tx.subcategoryName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(CategoryCatalog.all) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.name)
                            }
                            .tag(cat.id)
                        }
                    }
                    .onChange(of: selectedCategoryId) { _, newCatId in
                        // If user changes category, clear subcategory if it doesn't belong
                        let allowed = CategoryCatalog.byId(newCatId)?.subcategories ?? []
                        if let sub = selectedSubcategory, !allowed.contains(sub) {
                            selectedSubcategory = nil
                        }
                    }
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
                    let subs = CategoryCatalog.byId(selectedCategoryId)?.subcategories ?? []

                    Picker("Subcategory", selection: $selectedSubcategory) {
                        Text("None").tag(String?.none)
                        ForEach(subs, id: \.self) { sub in
                            Text(sub).tag(String?.some(sub))
                        }
                    }
                    .disabled(subs.isEmpty)
                }

                Section("Date") {
                    DatePicker("Date", selection: $tx.date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Note (optional)") {
                    TextField("Note", text: Binding(
                        get: { tx.note ?? "" },
                        set: { tx.note = $0.isEmpty ? nil : $0 }
                    ))
                    .focused($focusedField, equals: .note)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(parseAmount() == nil)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear { focusedField = .amount }
        }
    }

    private func parseAmount() -> Decimal? {
        let cleaned = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned)
    }

    private func save() {
        guard let amount = parseAmount(), amount > 0 else { return }

        // amount sign
        tx.signedAmount = (kind == .expense) ? amount : -amount

        // apply category + subcategory edits
        tx.categoryId = selectedCategoryId
        tx.categoryName = CategoryCatalog.byId(selectedCategoryId)?.name ?? selectedCategoryId
        tx.subcategoryName = selectedSubcategory

        do { try modelContext.save() } catch { print("Edit save failed:", error) }
        dismiss()
    }
}
