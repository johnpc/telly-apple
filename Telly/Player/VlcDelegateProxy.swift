import Foundation
import VLCKit

/// NSObject shim for `VLCMediaPlayerDelegate` so the engine need not subclass
/// NSObject — whose `release()` would clash with the `PlayerEngine.release()`
/// requirement. Forwards VLC's state-changed callback (delivered on the main
/// thread) to the engine's main-actor handler. VLCKit 4 delivers the new state
/// as a parameter rather than a `Notification`; the engine re-reads
/// `player.state`, so the value is ignored here.
final class VlcDelegateProxy: NSObject, VLCMediaPlayerDelegate {
    var onStateChange: @MainActor () -> Void = {}
    /// Fired alongside every state change so the PiP window (iOS) can refresh its
    /// transport UI via `invalidatePlaybackState`; a no-op default on tvOS.
    var onInvalidate: @MainActor () -> Void = {}

    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        MainActor.assumeIsolated { onStateChange(); onInvalidate() }
    }
}
