import Foundation

/// Our own mirror of VLCKit's `VLCMediaPlayerState`, decoupled from the
/// framework so the raw-state → ``PlayerState`` mapping (``PlaybackReducer``.
/// ``PlaybackReducer/onVlcState(_:)``) is a pure, unit-testable seam that does
/// not need to link VLCKit (an app-target-only dependency the test target
/// never imports). The thin delegate glue in ``VLCKitPlayerEngine`` translates
/// each `VLCMediaPlayerState` into one of these cases and nothing else.
enum VlcPlaybackState: Equatable {
    case opening
    case buffering
    /// Elementary streams added — decoding has begun and frames are flowing,
    /// so this counts as playing even when VLCKit never emits a clean
    /// `.playing` afterward (it commonly parks on `.esAdded`/`.buffering`).
    case esAdded
    case playing
    case paused
    case stopped
    case ended
    case error
}
