import SwiftUI

/// The fullscreen block-PIN challenge layer for ``LivePlaybackScreen``, kept in
/// its own sibling so the screen's ZStack just applies it in one line (matching
/// the other overlay builders). When the gate has a `pending` blocked channel it
/// raises the reused ``PinChallengeSheetView`` full-screen OVER the video — so it
/// renders even where the simulator cannot decode the stream. The card reuses
/// ``ParentalStore/verify(pin:)`` via ``LivePlaybackModel/submitBlockPin(_:)``:
/// a correct PIN tunes the now-unlocked channel and clears the prompt, a wrong
/// one clears the field for a retry, and Cancel dismisses without tuning. The
/// PIN is never logged.
extension LivePlaybackScreen {
    /// Presented iff the gate is holding a blocked channel; dismissing (Cancel)
    /// clears the pending challenge without tuning.
    var blockChallengePresented: Binding<Bool> {
        Binding(get: { model.blockGate?.pending != nil },
                set: { if !$0 { model.blockGate?.dismiss() } })
    }

    @ViewBuilder var blockChallenge: some View {
        PinChallengeSheetView { model.submitBlockPin($0) }
    }
}
