import Testing
@testable import Telly

/// The pure VOD key→command mapper: OK toggles pause, D-pad LEFT/RIGHT seek the
/// 10 s step, RW/FF jump the 30 s step, UP/DOWN reveal the transport, and every
/// unowned remote key falls through as `nil` so the screen's BACK handler wins.
struct VodPlaybackKeysTests {
    @Test func okTogglesPause() {
        #expect(VodPlaybackKeys.command(.ok) == .togglePause)
    }

    @Test func leftRightSeekTenSeconds() {
        #expect(VodPlaybackKeys.command(.left) == .seek(deltaMs: -10_000))
        #expect(VodPlaybackKeys.command(.right) == .seek(deltaMs: 10_000))
    }

    @Test func rewindFastForwardJumpThirtySeconds() {
        #expect(VodPlaybackKeys.command(.rewind) == .seek(deltaMs: -30_000))
        #expect(VodPlaybackKeys.command(.fastForward) == .seek(deltaMs: 30_000))
    }

    @Test func upDownRevealTheTransport() {
        #expect(VodPlaybackKeys.command(.up) == .revealTransport)
        #expect(VodPlaybackKeys.command(.down) == .revealTransport)
    }

    @Test func unownedKeysAreUnhandled() {
        #expect(VodPlaybackKeys.command(.back) == nil)
        #expect(VodPlaybackKeys.command(.menu) == nil)
        #expect(VodPlaybackKeys.command(.longOk) == nil)
        #expect(VodPlaybackKeys.command(.channelUp) == nil)
        #expect(VodPlaybackKeys.command(.channelDown) == nil)
    }

    @Test func seekStepsMatchTheModelConstants() {
        #expect(VodPlaybackKeys.command(.left) == .seek(deltaMs: -VodPlaybackModel.seekStepMs))
        #expect(VodPlaybackKeys.command(.fastForward) == .seek(deltaMs: VodPlaybackModel.jumpStepMs))
    }
}
