import Foundation

/// Pure channel-adjacency math: restore-on-start and wrap-around zapping.
/// Ported 1:1 from Android `ChannelZapper` (ChannelZapper.kt:6-28). No engine,
/// no clock — the S6 orchestrator turns a neighbour result into an actual tune.
enum ChannelZapper {
    /// The last-watched channel if it still exists, else the first channel.
    static func restore(_ channels: [ChannelEntity], lastChannelId: Int?) -> ChannelEntity? {
        channels.first { $0.id == lastChannelId } ?? channels.first
    }

    /// The channel `delta` steps from `current` in list order, wrapping at both
    /// ends. Ports `ChannelZapper.neighbour`; empty -> nil, current-absent -> first.
    static func neighbour(_ channels: [ChannelEntity], current: ChannelEntity?, delta: Int) -> ChannelEntity? {
        if channels.isEmpty { return nil }
        guard let index = channels.firstIndex(where: { $0.id == current?.id }) else { return channels.first }
        let n = channels.count
        return channels[((index + delta) % n + n) % n]   // floor-mod = Kotlin .mod()
    }
}
