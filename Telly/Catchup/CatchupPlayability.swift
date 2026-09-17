import Foundation

/// Whether a PAST guide cell is playable as catch-up: the channel declares a
/// usable catch-up capability, the cell holds a real programme (not an EPG
/// "No information" filler), it has fully aired, and its start still lies within
/// the channel's `catchup-days` horizon. Airing/future cells and anything else
/// keep today's behaviour. Ported 1:1 from Android `CatchupPlayability`
/// (CatchupPlayability.kt:12-24).
enum CatchupPlayability {
    /// One day in milliseconds (Android `DAY_MS`, CatchupPlayability.kt:12).
    static let dayMs = 24 * 3_600_000

    /// False when the cell is filler, still airing/future (`endMs > nowMs`), the
    /// channel has no catch-up capability, or the start predates the horizon.
    /// The horizon boundary (`startMs == nowMs - days*dayMs`) is playable.
    static func playable(channel: ChannelEntity, startMs: Int, endMs: Int,
                         hasInfo: Bool, nowMs: Int) -> Bool {
        guard hasInfo, endMs <= nowMs else { return false }
        guard let attributes = channel.catchupAttributes() else { return false }
        return startMs >= nowMs - attributes.days * dayMs
    }
}
