import SwiftUI

/// The masked PIN entry sheet used to set/change a PIN or confirm the current
/// one before disabling it. Format is validated via ``PinPolicy`` (Confirm stays
/// disabled until four digits are entered); the raw PIN is handed to `onSubmit`,
/// which returns whether it was accepted. A rejected PIN clears the field for a
/// retry. The PIN is never logged. The masked-entry scaffold is shared with
/// ``PinChallengeSheetView`` via ``PinPromptView`` so nothing is duplicated.
struct PinEntrySheetView: View {
    let mode: PinEntryMode
    let onSubmit: (String) -> Bool

    var body: some View {
        PinPromptView(title: mode.title, prompt: mode.prompt,
                      confirmLabel: "Confirm", onSubmit: onSubmit)
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
