#if os(iOS)
import UIKit
import VLCKit

/// The PiP-capable VLC render target. VLCKit messages the drawable's
/// `addSubview:` / `bounds` selectors via the ObjC runtime (a plain `UIView`
/// already responds — the same untyped-`drawable` path VLCKit uses for the
/// non-PiP surface, so no formal `VLCDrawable` conformance is needed; that
/// protocol's `bounds()` is imported as a method that would clash with
/// `UIView.bounds`). On top of that it vends a ``PipMediaController`` and retains
/// the `VLCPictureInPictureWindowControlling` VLCKit hands back through the
/// `pictureInPictureReady` block. VLCKit owns the AVKit internals — pure device
/// glue. iOS/iPadOS only.
final class PipDrawableView: UIView, VLCPictureInPictureDrawable {
    private let controller: PipMediaController
    private var windowController: VLCPictureInPictureWindowControlling?

    init(engine: any PlayerEngine) {
        controller = PipMediaController(engine: engine)
        super.init(frame: .zero)
        backgroundColor = .black
    }

    @available(*, unavailable) required init?(coder: NSCoder) { nil }

    func mediaController() -> VLCPictureInPictureMediaControlling { controller }

    func pictureInPictureReady() -> (VLCPictureInPictureWindowControlling?) -> Void {
        { [weak self] window in self?.windowController = window }
    }

    /// Called by the engine when the user taps the PiP quick-bar slot.
    func startPictureInPicture() { windowController?.startPictureInPicture() }
    /// Refresh the PiP transport UI after a state change (wired via the proxy).
    func invalidate() { windowController?.invalidatePlaybackState() }
}

/// Bridges VLCKit-4's PiP transport callbacks to our engine-agnostic
/// ``PlayerEngine``. VLCKit invokes these on the main thread to drive the PiP
/// window's controls; each forwards to the injected engine, with the pure
/// seek/playing arithmetic delegated to the tested ``PipMediaState``.
final class PipMediaController: NSObject, VLCPictureInPictureMediaControlling {
    private let engine: any PlayerEngine
    init(engine: any PlayerEngine) { self.engine = engine }

    func play() { MainActor.assumeIsolated { engine.resume() } }
    func pause() { MainActor.assumeIsolated { engine.pause() } }

    func seek(by offset: Int64, completion: (@Sendable () -> Void)!) {
        MainActor.assumeIsolated {
            engine.seek(toMs: PipMediaState.seekTarget(
                positionMs: engine.positionMs, durationMs: engine.durationMs,
                offsetMs: Int(offset)))
        }
        completion?()
    }

    func mediaLength() -> Int64 { MainActor.assumeIsolated { Int64(engine.durationMs) } }
    func mediaTime() -> Int64 { MainActor.assumeIsolated { Int64(engine.positionMs) } }
    func isMediaSeekable() -> Bool { MainActor.assumeIsolated { engine.isSeekable } }
    func isMediaPlaying() -> Bool {
        MainActor.assumeIsolated { PipMediaState.isPlaying(engine.state) }
    }
}
#endif
