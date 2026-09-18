import Foundation

/// Platform-neutral derived state extracted from ``LivePlaybackModel`` to keep
/// the core type under the line cap: the tuned channel's now/next, the overlay
/// layer to render this frame, and whether to hold the last frame instead of a
/// buffering spinner. All read tracked stored state, so SwiftUI still observes
/// them from this extension.
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
