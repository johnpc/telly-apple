import Foundation
import VLCKitSPM

/// NSObject shim for `VLCMediaPlayerDelegate` so the engine need not subclass
/// NSObject — whose `release()` would clash with the `PlayerEngine.release()`
/// requirement. Forwards VLC's state-changed notification (delivered on the
/// main thread) to the engine's main-actor handler.
final class VlcDelegateProxy: NSObject, VLCMediaPlayerDelegate {
    var onStateChange: @MainActor () -> Void = {}

    func mediaPlayerStateChanged(_ notification: Notification) {
        MainActor.assumeIsolated { onStateChange() }
    }
}
