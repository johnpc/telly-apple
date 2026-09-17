import Foundation

/// Whether the UI should hold the previous video frame (TiviMate's frozen frame
/// under the compact zap overlay) instead of a buffering spinner while a
/// just-zapped stream re-tunes. Pure + clock-injected.
///
/// APPLE-PORT ADDITION: Android keeps the frame implicitly (Media3 never clears
/// the surface). VLCKit blanks the surface on media swap, so the hold must be an
/// explicit, timed decision. `graceMs` aligns with the zap-overlay lifetime
/// (PanelTimeouts.zapMs, 5_500).
struct ZapKeepFrame: Equatable {
    private var holdUntilMs: Int?
    private let graceMs: Int

    init(graceMs: Int = 5_500) { self.graceMs = graceMs }

    mutating func onZapTune(at nowMs: Int) { holdUntilMs = nowMs + graceMs }
    mutating func onPlaying() { holdUntilMs = nil }

    /// True while a fresh zap is settling and the engine is not yet playing.
    func holdsLastFrame(state: PlayerState, at nowMs: Int) -> Bool {
        guard case .buffering = state else { return false }
        guard let until = holdUntilMs, nowMs < until else { return false }
        return true
    }
}
