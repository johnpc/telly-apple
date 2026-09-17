import SwiftUI

/// The masked PIN challenge presented when a blocked channel is tapped: the user
/// must enter the correct PIN before the channel tunes. Reuses the shared
/// ``PinPromptView`` scaffold (which itself reuses ``PinDigitsFieldView``) so the
/// masked-entry wiring is never duplicated. `onUnlock` receives the entered PIN
/// and returns whether it was correct; a correct PIN dismisses and lets the
/// caller tune, a wrong PIN clears the field for a retry, and Cancel dismisses
/// without ever tuning. The PIN is never logged.
struct PinChallengeSheetView: View {
    let onUnlock: (String) -> Bool

    var body: some View {
        PinPromptView(title: "Locked Channel",
                      prompt: "Enter your PIN to unlock this channel",
                      confirmLabel: "Unlock", onSubmit: onUnlock)
    }
}
