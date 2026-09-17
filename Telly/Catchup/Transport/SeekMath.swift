import Foundation

/// Pure integer transport math for catch-up seeking. No clock, no engine, no
/// VLCKit — just bounds arithmetic over milliseconds. Ports the Android
/// `CatchupPlayback.seekBy` clamp and `CatchupProgrammeHop.rewindFromLive`
/// offset.
enum SeekMath {

    /// Absolute target for a relative seek: `current + delta`, clamped to the
    /// archive window `0...duration`. A negative `duration` yields `0`.
    static func seekBy(current: Int, delta: Int, duration: Int) -> Int {
        guard duration >= 0 else { return 0 }
        return min(max(current + delta, 0), duration)
    }

    /// Offset from a programme start when rewinding from the live edge:
    /// `now - delta - start`, floored at `0`.
    static func rewindLiveOffset(nowMs: Int, deltaMs: Int, startMs: Int) -> Int {
        max(0, nowMs - deltaMs - startMs)
    }
}
