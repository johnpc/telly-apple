import Foundation

/// The unlock→tune bridge for the fullscreen block-PIN overlay, kept in its own
/// sibling so `+Tune.swift` stays within the source-line budget. The screen's
/// reused ``PinChallengeSheetView`` calls ``submitBlockPin(_:)`` with the entered
/// PIN; verification and the one-shot pass live in ``PlaybackBlockGate`` (which
/// delegates to ``ParentalStore/verify(pin:)`` — the PIN is never re-hashed or
/// logged here). A correct PIN clears `pending` and tunes the channel; a wrong
/// one returns false so the prompt clears its field for a retry.
extension LivePlaybackModel {
    /// Submit the entered PIN for the currently-pending blocked channel. Returns
    /// whether it was accepted (true also tunes the now-unlocked channel).
    @discardableResult
    func submitBlockPin(_ pin: String) -> Bool {
        guard let channel = blockGate?.unlock(pin: pin) else { return false }
        tune(channel)
        return true
    }
}
