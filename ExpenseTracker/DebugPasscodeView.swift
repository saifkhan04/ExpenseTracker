import SwiftUI

struct DebugPasscodeView: View {
    let expected: String
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Enter passcode") {
                    SecureField("Passcode", text: $code)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                }

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Debug Access")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unlock") { unlock() }
                        .disabled(code.isEmpty)
                }
            }
        }
    }

    private func unlock() {
        if code == expected {
            dismiss()
            onSuccess()
        } else {
            errorText = "Wrong passcode"
            code = ""
        }
    }
}
