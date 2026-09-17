import Foundation

/// Key routing for the transport model: consults ``CatchupKeyPolicy`` and
/// dispatches the command it yields. Ports the Android `CatchupKeyRouting.onKey`
/// + `CatchupPlayback.seekBy`.
extension CatchupPlaybackModel {
    /// Routes a key through the catch-up policy; `true` iff catch-up owned it
    /// (the caller falls through to the live map on `false`).
    func onKey(_ key: PlaybackKey, overlay: PlaybackOverlay) -> Bool {
        guard let command = CatchupKeyPolicy.command(
            overlay: overlay, key: key, mode: mode, keys: keys, skip: skip) else { return false }
        switch command {
        case let .seek(delta): seekBy(delta)
        case let .rewindLive(delta): rewindLive(deltaMs: delta)
        case .back: back()
        }
        return true
    }

    /// Relative seek within the archive, clamped to the window and pinned into
    /// the tracker so the row updates before the next engine sample.
    func seekBy(_ delta: Int) {
        let target = SeekMath.seekBy(current: tracker.position, delta: delta, duration: durationMs)
        engine.seek(toMs: target)
        tracker.set(target)
    }
}
