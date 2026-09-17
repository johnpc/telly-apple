import Foundation
import VLCKitSPM

/// Catch-up transport for the real engine, split from the primary adapter to
/// keep it within the source-line budget (the `+Audio` precedent). `player.time`
/// is honoured only for seekable media, so a non-seekable archive is treated as
/// position-only; `VLCTime.intValue` is milliseconds as `Int32` (well within the
/// <24-day horizon of a catch-up window). Untestable device glue by nature.
extension VLCKitPlayerEngine {
    var positionMs: Int { Int(player.time.intValue) }

    func pause() { player.pause() }

    func resume() { player.play() }

    func seek(toMs ms: Int) {
        guard player.isSeekable else { return }
        player.time = VLCTime(int: Int32(ms))
    }
}
