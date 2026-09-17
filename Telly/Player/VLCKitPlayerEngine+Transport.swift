import Foundation
import VLCKit

/// Catch-up transport for the real engine, split from the primary adapter to
/// keep it within the source-line budget (the `+Audio` precedent). `player.time`
/// is honoured only for seekable media, so a non-seekable archive is treated as
/// position-only. VLCKit 4 exposes the time as `VLCTime.value` (NSNumber, ms);
/// millisecond magnitudes are well within the <24-day catch-up horizon.
/// Untestable device glue by nature.
extension VLCKitPlayerEngine {
    var positionMs: Int { player.time.value?.intValue ?? 0 }

    var durationMs: Int { player.media?.length.value?.intValue ?? 0 }

    func pause() { player.pause() }

    func resume() { player.play() }

    func seek(toMs ms: Int) {
        guard player.isSeekable else { return }
        player.time = VLCTime(number: NSNumber(value: ms))
    }
}
