import Testing
@testable import Telly

/// The pure raw-VLC-state → `PlayerState` mapping (`PlaybackReducer.onVlcState`),
/// exercised without linking VLCKit. Covers every `VlcPlaybackState` case —
/// notably that `.esAdded` reaches `.playing` (the buffering-spinner fix) so a
/// rendering stream leaves `.buffering`.
struct VlcStateMappingTests {
    private func reducerAfterLoad() -> PlaybackReducer {
        var r = PlaybackReducer()
        r.onLoad()
        return r
    }

    @Test func openingMapsToBuffering() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.opening) == nil)
        #expect(r.state == .buffering)
    }

    @Test func bufferingMapsToBuffering() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.buffering) == nil)
        #expect(r.state == .buffering)
    }

    @Test func esAddedReachesPlaying() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.esAdded) == nil)
        #expect(r.state == .playing)
    }

    @Test func playingMapsToPlaying() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.playing) == nil)
        #expect(r.state == .playing)
    }

    @Test func endedMapsToEnded() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.ended) == nil)
        #expect(r.state == .ended)
    }

    @Test func stoppedMapsToIdle() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.stopped) == nil)
        #expect(r.state == .idle)
    }

    @Test func pausedLeavesStateUnchanged() {
        var r = reducerAfterLoad()
        r.onVlcState(.esAdded)
        #expect(r.onVlcState(.paused) == nil)
        #expect(r.state == .playing)
    }

    @Test func errorReturnsReconnectEffectAndState() {
        var r = reducerAfterLoad()
        #expect(r.onVlcState(.error) == .reconnect(delayMs: 1_000))
        #expect(r.state == .reconnecting)
    }

    @Test func playingAfterReconnectRestartsBudget() {
        var r = reducerAfterLoad()
        _ = r.onVlcState(.error)
        r.onVlcState(.esAdded)
        // Budget reset: the next error is a fresh first attempt (1s), not the
        // doubled backoff.
        #expect(r.onVlcState(.error) == .reconnect(delayMs: 1_000))
    }
}
