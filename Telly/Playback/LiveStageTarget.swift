import Foundation

/// Identifies a live channel selection any entry point (home, History, My List,
/// Search, the pushed Guide) presents the shared live stage over. Reusing one
/// target type + one `.liveStageCover` modifier keeps every live launch on the
/// SAME persistent engine (``LiveEngineStore``) — a seamless zap with the guide
/// overlay + mini-player — instead of minting a fresh per-screen engine that
/// would reconnect the stream. Kept a plain value so the channel→target mapping
/// is unit-testable without a view.
struct LiveStageTarget: Identifiable {
    let id: Int
    let url: String
}

extension LiveStageTarget {
    /// The mapping every live entry point shares: a channel's id + stream URL.
    init(channel: ChannelEntity) {
        self.init(id: channel.id, url: channel.source.streamUrl)
    }
}
