import Foundation

/// What a VOD-playback key press means, before the screen dispatches it onto the
/// model. Mirrors the Android `VodCommand` shape and the ``PlaybackCommand`` /
/// ``CatchupCommand`` precedent: a pure value the mapper yields and the screen
/// interprets.
enum VodKeyCommand: Equatable, Sendable {
    /// OK: toggle pause/resume.
    case togglePause
    /// LEFT/RIGHT (±10 s) and RW/FF (±30 s): relative seek within the movie.
    case seek(deltaMs: Int)
    /// UP/DOWN: reveal the auto-hiding transport without changing playback.
    case revealTransport
}

/// Pure key→command mapper for VOD playback (Apple mirror of Android's
/// `VodPlaybackScreenKeys`): OK pauses, LEFT/RIGHT seek 10 s, RW/FF jump 30 s,
/// UP/DOWN reveal the transport. Everything else (BACK, MENU, CH±, long-OK) is
/// unowned — the screen's own BACK handler persists+exits, so the mapper returns
/// `nil` and the caller treats the key as unhandled.
enum VodPlaybackKeys {
    static func command(_ key: PlaybackKey) -> VodKeyCommand? {
        switch key {
        case .ok: return .togglePause
        case .left: return .seek(deltaMs: -VodPlaybackModel.seekStepMs)
        case .right: return .seek(deltaMs: VodPlaybackModel.seekStepMs)
        case .rewind: return .seek(deltaMs: -VodPlaybackModel.jumpStepMs)
        case .fastForward: return .seek(deltaMs: VodPlaybackModel.jumpStepMs)
        case .up, .down: return .revealTransport
        case .longOk, .menu, .back, .channelUp, .channelDown: return nil
        }
    }
}
