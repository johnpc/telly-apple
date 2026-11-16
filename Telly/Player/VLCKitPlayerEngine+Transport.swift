import Foundation
import VLCKitSPM

/// Catch-up transport for the real engine, split from the primary adapter to
/// keep it within the source-line budget (the `+Audio` precedent). `player.time`
/// is honoured only for seekable media, so a non-seekable archive is treated as
/// position-only; `VLCTime.intValue` is milliseconds as `Int32` (well within the
/// <24-day horizon of a catch-up window). Control calls go through the engine's
/// serial `control` queue (see the adapter) so the main actor never blocks on libVLC.
extension VLCKitPlayerEngine {
    var positionMs: Int { Int(player.time.intValue) }

    var durationMs: Int { Int(player.media?.length.intValue ?? 0) }

    func pause() { let player = self.player; control.async { player.pause() } }

    func resume() { let player = self.player; control.async { player.play() } }

    func seek(toMs ms: Int) {
        guard player.isSeekable else { return }
        let player = self.player, time = VLCTime(int: Int32(ms))
        control.async { player.time = time }
    }
}
