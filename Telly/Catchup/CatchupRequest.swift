import Foundation

/// A resolved request to play a channel's archived programme: the built
/// catch-up URL and the window it spans. Mirrors the Android catch-up hand-off.
struct CatchupRequest: Equatable {
    let channel: ChannelEntity
    let url: String
    let title: String?
    let startMs: Int
    let endMs: Int

    var durationMs: Int { endMs - startMs }
}
