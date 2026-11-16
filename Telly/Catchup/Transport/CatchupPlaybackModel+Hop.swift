import Foundation

/// Programme-hop + session lifecycle for the transport model: ⏮/⏭, rewind from
/// live, enter/toLive/back, and the finished-archive → live check. Ports the
/// Android `CatchupProgrammeHop` + `CatchupPlayback` enter/toLive/back/Ended.
extension CatchupPlaybackModel {
    /// ⏮ to the previous archived programme, or stay put when there is none.
    func previous() {
        guard let state, let request = neighbours.previous(state.request) else { return }
        enter(request, fromLive: false)
    }

    /// ⏭ to the next archive, or back to live at the newest edge.
    func next() {
        guard let state else { return }
        switch neighbours.next(state.request) {
        case let .archive(request): enter(request, fromLive: false)
        case .live: toLive()
        }
    }

    /// Rewind from live into catch-up of the airing programme, then seek to the
    /// live edge minus `deltaMs`. Ports `CatchupProgrammeHop.rewindFromLive`.
    func rewindLive(deltaMs: Int) {
        guard let channel = stage.channel,
              let request = liveEdge.requestFor(channel) else { return }
        enter(request, fromLive: true)
        let offset = SeekMath.rewindLiveOffset(nowMs: now(), deltaMs: deltaMs, startMs: request.startMs)
        engine.seek(toMs: offset)
        tracker.set(offset)
    }

    /// Enter an archive session: pin the state, reset the position, load the URL.
    func enter(_ request: CatchupRequest, fromLive: Bool) {
        stage = .archive(CatchupState(request: request, fromLive: fromLive))
        tracker.reset()
        engine.load(request.url)
    }

    /// Return to live of the same channel: the stage keeps the channel (so a
    /// later rewind works), and the engine tunes the live URL.
    func toLive() {
        guard let channel = stage.channel else { return }
        stage = .live(channel)
        engine.load(channel.source.streamUrl, isLive: true)
    }

    /// BACK: an archive entered from live returns to live; anything else leaves
    /// the transport (idle) and exits to the guide.
    func back() {
        if case let .archive(state) = stage, state.fromLive {
            toLive()
        } else {
            stage = .idle
            onExitToGuide()
        }
    }

    /// The screen's ticker calls this; a finished archive returns to live.
    func handleEndedIfNeeded() {
        if case .archive = stage, engine.state == .ended { toLive() }
    }
}
