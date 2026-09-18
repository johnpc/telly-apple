#if os(iOS)
import Foundation

/// Pure PiP transport arithmetic shared by the VLCKit-4 PiP media controller so
/// the decision logic stays testable off-device (the controller itself is
/// untestable ObjC-protocol glue). Maps engine ``PlayerState`` to the PiP window's
/// "is playing" flag and clamps a relative seek target into the valid range.
/// iOS/iPadOS only — tvOS has no system PiP.
enum PipMediaState {
    /// True only while frames are actually being presented (PiP pause button up).
    static func isPlaying(_ state: PlayerState) -> Bool { state == .playing }

    /// Clamp `positionMs + offsetMs` into `0...durationMs`. A `durationMs` of 0
    /// means live / unknown length, so only the lower bound (0) is enforced.
    static func seekTarget(positionMs: Int, durationMs: Int, offsetMs: Int) -> Int {
        let target = max(0, positionMs + offsetMs)
        return durationMs > 0 ? min(target, durationMs) : target
    }
}
#endif
