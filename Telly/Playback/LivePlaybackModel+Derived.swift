import Foundation

/// The screen-facing derived state of ``LivePlaybackModel``, split into a
/// same-module extension so the main type stays within the source-line budget
/// once the block-gate seam lands. These are pure computed views over the
/// tracked stored properties (`current` / `visibility` / `keepFrame`), so the
/// `@Observable` macro still tracks their inputs and the screen re-renders as
/// before — a pure move, no behaviour change.
extension LivePlaybackModel {
    /// The now/next for the currently tuned channel, or nil when none.
    var currentInfo: NowNext? { current.flatMap(nowNext) }

    /// The overlay layer the screen should render this frame.
    var overlay: PlaybackOverlay { visibility.overlay }

    /// Whether to hold the last video frame instead of a buffering spinner now.
    var holdsLastFrame: Bool {
        #if DEBUG
        if debugHoldFrame { return true }
        #endif
        return keepFrame.holdsLastFrame(state: engine.state, at: now())
    }
}
