import SwiftUI

/// The masked PIN entry sheet used to set/change a PIN or confirm the current
/// one before disabling it. Format is validated via ``PinPolicy`` (Confirm stays
/// disabled until four digits are entered); the raw PIN is handed to `onSubmit`,
/// which returns whether it was accepted. A rejected PIN clears the field for a
/// retry. The PIN is never logged. Slice 4's challenge sheet reuses
/// ``PinDigitsFieldView`` so the masked-entry wiring lives in one place.
struct PinEntrySheetView: View {
    let mode: PinEntryMode
    let onSubmit: (String) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(mode.prompt) { PinDigitsFieldView(pin: $pin) }
            }
            .navigationTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm", action: confirm).disabled(!PinPolicy.isValid(pin))
                }
            }
        }
    }

    private func confirm() {
        if onSubmit(pin) { dismiss() } else { pin = "" }
    }
}

/// The two ways the entry sheet is presented: setting/changing a PIN, or
/// confirming the current PIN before disabling it. Drives the sheet's copy.
enum PinEntryMode: Identifiable {
    case set, disable

    var id: Self { self }
    var title: String { self == .set ? "Set PIN" : "Disable PIN" }
    var prompt: String { self == .set ? "Enter a new 4-digit PIN" : "Enter your current PIN" }
}
