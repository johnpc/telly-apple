import Foundation

/// The semantic commands the key policy emits for the (un-ported) command
/// executor to run — ported from the Android `PlaybackCommand` sealed interface.
/// `nothing` is the explicit no-op the policy returns when a key is unbound in
/// the active context (Android's policy returns a nullable command; the Swift
/// policy is total and returns `.nothing` rather than `nil`). Android's
/// `PinTransport` is trimmed: it is emitted only by the catch-up key policy (an
/// un-ported slice), never by `PlaybackKeyPolicy`.
enum PlaybackCommand: Equatable, Sendable {
    /// Show the bottom info overlay.
    case showInfo
    /// Expand the info overlay's transport row (auto-hiding).
    case showTransport
    /// BACK at bare playback: leave the player for the TV guide.
    case exitToGuide
    /// Change channel by `delta` (+1 up, -1 down).
    case zap(delta: Int)
    /// Open the bottom icon quick-bar.
    case openQuickBar
    /// Open the channel list panel at the tuned row.
    case openPanel
    /// Hide the active transient overlay.
    case dismiss
    /// BACK out of a channel sheet: return to the channel panel.
    case backToPanel
    /// One-level BACK from a pushed screen: pop to the given overlay.
    case popTo(PlaybackOverlay)
    /// Open the N-up multiview grid over live playback.
    case openMultiview
    /// Move the active multiview tile one D-pad step (wrapping at edges).
    case moveMultiviewActive(MultiviewDirection)
    /// Promote the active multiview tile to fullscreen: exit, then tune it.
    case promoteMultiviewActive
    /// Leave multiview, returning to single-stream playback.
    case exitMultiview
    /// The key is unbound in this context: do nothing.
    case nothing
}
