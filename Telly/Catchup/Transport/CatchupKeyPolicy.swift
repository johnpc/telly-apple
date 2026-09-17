import Foundation

/// The catch-up context extending `PlaybackKeyPolicy`: consulted first, and only
/// for the keys the Remote-control toggles hand to seeking; everything it
/// declines falls through to the live key map. RW/FF work over the transient
/// overlays too; LEFT/RIGHT and DOWN/UP seeks apply at bare playback only. Ports
/// the Android `CatchupKeyPolicy` (`CatchupKeyPolicy.kt:60-125`).
enum CatchupKeyPolicy {
    static func command(
        overlay: PlaybackOverlay,
        key: PlaybackKey,
        mode: CatchupMode,
        keys: CatchupSeekKeys,
        skip: CatchupSkip
    ) -> CatchupCommand? {
        switch mode {
        case .none: return nil
        case .liveCapable: return duringLive(overlay, key, keys, skip)
        case .playing: return duringCatchup(overlay, key, keys, skip)
        }
    }

    /// Bare playback + the transient overlays; sticky layers keep their own keys.
    private static func transient(_ overlay: PlaybackOverlay) -> Bool {
        overlay == .none || overlay == .info || overlay == .infoTransport || overlay == .zapInfo
    }

    /// The "rewind live with catch-up" toggles (RW anywhere transient, LEFT/DOWN at bare).
    private static func duringLive(
        _ overlay: PlaybackOverlay, _ key: PlaybackKey, _ keys: CatchupSeekKeys, _ skip: CatchupSkip
    ) -> CatchupCommand? {
        guard transient(overlay) else { return nil }
        if key == .rewind, keys.rwLive { return .rewindLive(deltaMs: skip.backMs) }
        guard overlay == .none else { return nil }
        if key == .left, keys.leftLive { return .rewindLive(deltaMs: skip.backMs) }
        if key == .down, keys.downLive { return .rewindLive(deltaMs: skip.backMs) }
        return nil
    }

    private static func duringCatchup(
        _ overlay: PlaybackOverlay, _ key: PlaybackKey, _ keys: CatchupSeekKeys, _ skip: CatchupSkip
    ) -> CatchupCommand? {
        guard transient(overlay) else { return nil }
        if key == .rewind, keys.rwFf { return .seek(deltaMs: -skip.backMs) }
        if key == .fastForward, keys.rwFf { return .seek(deltaMs: skip.forwardMs) }
        guard overlay == .none else { return nil }
        return atBareCatchup(key, keys, skip)
    }

    /// D-pad seeks + BACK apply at bare playback only (overlays own those keys).
    private static func atBareCatchup(
        _ key: PlaybackKey, _ keys: CatchupSeekKeys, _ skip: CatchupSkip
    ) -> CatchupCommand? {
        if key == .left, keys.leftRight { return .seek(deltaMs: -skip.backMs) }
        if key == .right, keys.leftRight { return .seek(deltaMs: skip.forwardMs) }
        if key == .down, keys.downUp { return .seek(deltaMs: -skip.backMs) }
        if key == .up, keys.downUp { return .seek(deltaMs: skip.forwardMs) }
        if key == .back { return .back }
        return nil
    }
}
