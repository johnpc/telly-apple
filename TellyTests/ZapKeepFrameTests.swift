import Testing
@testable import Telly

/// The timed keep-last-frame decision during a zap re-tune.
struct ZapKeepFrameTests {
    @Test func holdsFrameWhileBufferingInGrace() {
        var keep = ZapKeepFrame(graceMs: 5_500)
        keep.onZapTune(at: 0)
        #expect(keep.holdsLastFrame(state: .buffering, at: 100) == true)
    }

    @Test func stopsHoldingAfterGrace() {
        var keep = ZapKeepFrame(graceMs: 5_500)
        keep.onZapTune(at: 0)
        #expect(keep.holdsLastFrame(state: .buffering, at: 5_500) == false)
    }

    @Test func doesNotHoldWhenPlaying() {
        var keep = ZapKeepFrame(graceMs: 5_500)
        keep.onZapTune(at: 0)
        #expect(keep.holdsLastFrame(state: .playing, at: 100) == false)
    }

    @Test func onPlayingClearsHold() {
        var keep = ZapKeepFrame(graceMs: 5_500)
        keep.onZapTune(at: 0)
        keep.onPlaying()
        #expect(keep.holdsLastFrame(state: .buffering, at: 100) == false)
    }

    @Test func doesNotHoldWithoutZap() {
        let keep = ZapKeepFrame(graceMs: 5_500)
        #expect(keep.holdsLastFrame(state: .buffering, at: 100) == false)
    }

    @Test func doesNotHoldOnError() {
        var keep = ZapKeepFrame(graceMs: 5_500)
        keep.onZapTune(at: 0)
        #expect(keep.holdsLastFrame(state: .error("x"), at: 100) == false)
    }
}
