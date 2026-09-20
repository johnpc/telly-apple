#if os(iOS)
import UIKit
import VLCKit

/// VLCKit-4 public Picture-in-Picture wiring for the real engine, split from the
/// primary adapter (at the source-line cap) per the `+Transport`/`+Audio`
/// precedent. VLCKit owns the AVKit internals; we only hand it a PiP-capable
/// drawable and drive start plus window invalidation. Stopping PiP is driven by
/// VLCKit's own PiP-window controls (the window controller / stateChangeEvent
/// Handler), not app code, so no app-initiated stop is wired this slice.
/// iOS/iPadOS only.
extension VLCKitPlayerEngine {
    /// Install the PiP-capable drawable as VLC's render target and route the
    /// proxy's state-change fan-out to the PiP window's `invalidatePlaybackState`.
    func useDrawable(_ drawable: PipDrawableView) {
        player.drawable = drawable
        proxy.onInvalidate = { [weak drawable] in drawable?.invalidate() }
    }

    /// Begin system Picture-in-Picture once VLCKit has vended the window controller.
    func startPip() { (player.drawable as? PipDrawableView)?.startPictureInPicture() }
}
#endif
