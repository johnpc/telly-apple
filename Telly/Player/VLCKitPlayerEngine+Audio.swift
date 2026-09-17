import Foundation
import VLCKitSPM

/// Audio control for the real engine, split from the primary adapter to keep it
/// within the source-line budget. `muted` is a read-write VLCKit property
/// (`@property (getter=isMuted) BOOL muted`), so muting is a direct set — no
/// volume dance needed. Multiview mutes every tile but the active one.
extension VLCKitPlayerEngine {
    func setMuted(_ muted: Bool) {
        player.audio?.isMuted = muted
    }
}
