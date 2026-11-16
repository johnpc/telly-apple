import Foundation

/// The active archive session: the request being played and whether it was
/// entered by rewinding from live (so BACK returns to live rather than the
/// guide). Ports the Android `CatchupPlayback` state (`CatchupPlayback.kt:13-16`).
struct CatchupState: Equatable {
    let request: CatchupRequest
    let fromLive: Bool
}

/// Where the catch-up transport is, as ONE value: nothing yet, LIVE on a channel
/// (rewind-into-archive is available again), or inside an ARCHIVE session. The
/// explicit `.live` case is what lets rewind → live → rewind work: the channel is
/// remembered after returning to live instead of being dropped with a `nil`.
enum CatchupStage: Equatable {
    case idle
    case live(ChannelEntity)
    case archive(CatchupState)

    /// The key-policy context this stage maps to.
    var mode: CatchupMode {
        switch self {
        case .idle: return .none
        case .live: return .liveCapable
        case .archive: return .playing
        }
    }

    /// The channel the transport is on, in either live or archive playback.
    var channel: ChannelEntity? {
        switch self {
        case .idle: return nil
        case let .live(channel): return channel
        case let .archive(state): return state.request.channel
        }
    }
}
