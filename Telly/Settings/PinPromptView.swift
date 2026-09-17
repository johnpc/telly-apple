import SwiftUI

/// The shared masked-PIN prompt scaffold behind both ``PinEntrySheetView`` (set /
/// change / disable) and ``PinChallengeSheetView`` (unlock a locked channel), so
/// the `NavigationStack` / `Form` / Cancel-Confirm wiring lives in exactly one
/// place (no duplication). `onSubmit` receives the entered PIN and returns
/// whether it was accepted: accepted dismisses, rejected clears the field for a
/// retry, and Cancel dismisses without submitting. The raw PIN is never logged.
struct PinPromptView: View {
    let title: String
    let prompt: String
    let confirmLabel: String
    let onSubmit: (String) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(prompt) { PinDigitsFieldView(pin: $pin) }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel, action: submit).disabled(!PinPolicy.isValid(pin))
                }
            }
        }
    }

    private func submit() {
        if onSubmit(pin) { dismiss() } else { pin = "" }
    }
}
