#if os(iOS)
import Foundation

/// Pure decision for whether the fullscreen quick-bar's Picture-in-Picture slot
/// is actionable right now. PiP needs the device/OS to support it — the injected
/// `AVPictureInPictureController.isPictureInPictureSupported()` Bool, kept out of
/// this pure type — AND live video actually playing (an idle/buffering/ended/
/// errored stream has no frames to hand the PiP window). The AVKit conformance
/// that consumes this lands in a later slice; here it only gates the entry point.
/// iOS/iPadOS only — tvOS has no system PiP.
enum PipEligibility {
    /// True when the slot should accept a tap: supported AND video is playing.
    static func isActionable(isSupported: Bool, state: PlayerState) -> Bool {
        isSupported && state == .playing
    }
}
#endif
