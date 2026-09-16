import Testing
@testable import Telly

/// The reconnect state machine: lifecycle transitions, backoff schedule, budget
/// exhaustion and reset semantics — all without a live VLC player.
struct PlaybackReducerTests {
    @Test func startsIdle() {
        let reducer = PlaybackReducer()
        #expect(reducer.state == .idle)
    }

    @Test func loadBuffers() {
        var reducer = PlaybackReducer()
        reducer.onLoad()
        #expect(reducer.state == .buffering)
    }

    @Test func bufferingEvent() {
        var reducer = PlaybackReducer()
        reducer.onBuffering()
        #expect(reducer.state == .buffering)
    }

    @Test func playingTransitions() {
        var reducer = PlaybackReducer()
        reducer.onPlaying()
        #expect(reducer.state == .playing)
    }

    @Test func endedTransitions() {
        var reducer = PlaybackReducer()
        reducer.onEnded()
        #expect(reducer.state == .ended)
    }

    @Test func stoppedReturnsToIdle() {
        var reducer = PlaybackReducer()
        reducer.onPlaying()
        reducer.onStopped()
        #expect(reducer.state == .idle)
    }

    @Test func firstErrorReconnectsAfterOneSecond() {
        var reducer = PlaybackReducer()
        reducer.onLoad()
        let effect = reducer.onError("drop")
        #expect(effect == .reconnect(delayMs: 1_000))
        #expect(reducer.state == .reconnecting)
    }

    @Test func successiveErrorsDoubleAndCap() {
        var reducer = PlaybackReducer()
        reducer.onLoad()
        let delays = (0..<6).map { _ -> Int in
            if case let .reconnect(d) = reducer.onError("drop") { return d }
            return -1
        }
        #expect(delays == [1_000, 2_000, 4_000, 8_000, 16_000, 30_000])
    }

    @Test func budgetSpentFails() {
        var reducer = PlaybackReducer()
        reducer.onLoad()
        for _ in 0..<6 { _ = reducer.onError("drop") }
        let effect = reducer.onError("fatal")
        #expect(effect == .fail)
        #expect(reducer.state == .error("fatal"))
    }

    @Test func playingBetweenErrorsRestartsBudget() {
        var reducer = PlaybackReducer()
        reducer.onLoad()
        _ = reducer.onError("drop")
        _ = reducer.onError("drop")
        reducer.onPlaying()
        let effect = reducer.onError("drop")
        #expect(effect == .reconnect(delayMs: 1_000))
    }

    @Test func stoppedRestartsBudget() {
        var reducer = PlaybackReducer()
        reducer.onLoad()
        _ = reducer.onError("drop")
        reducer.onStopped()
        reducer.onLoad()
        let effect = reducer.onError("drop")
        #expect(effect == .reconnect(delayMs: 1_000))
    }
}
