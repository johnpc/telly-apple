import Testing
@testable import Telly

/// Unit coverage for `CatchupKeyPolicy` — the ported catch-up command matrix.
struct CatchupKeyPolicyTests {
    private let keys = CatchupSeekKeys.appleDefaults
    private let skip = CatchupSkip.defaults

    private func command(
        _ overlay: PlaybackOverlay,
        _ key: PlaybackKey,
        _ mode: CatchupMode,
        keys: CatchupSeekKeys? = nil
    ) -> CatchupCommand? {
        CatchupKeyPolicy.command(
            overlay: overlay, key: key, mode: mode, keys: keys ?? self.keys, skip: skip
        )
    }

    @Test func modeNoneAlwaysNil() {
        #expect(command(.none, .rewind, .none) == nil)
        #expect(command(.none, .left, .none) == nil)
    }

    @Test func transientOverlaysAllowCommands() {
        #expect(command(.info, .rewind, .playing) == .seek(deltaMs: -10_000))
        #expect(command(.infoTransport, .rewind, .playing) == .seek(deltaMs: -10_000))
        #expect(command(.zapInfo, .rewind, .playing) == .seek(deltaMs: -10_000))
    }

    @Test func stickyOverlaysDeclineToNil() {
        #expect(command(.panel, .rewind, .playing) == nil)
        #expect(command(.quickBar, .rewind, .playing) == nil)
        #expect(command(.multiview, .rewind, .playing) == nil)
    }

    @Test func playingRewindAndFastForwardSeek() {
        #expect(command(.none, .rewind, .playing) == .seek(deltaMs: -10_000))
        #expect(command(.none, .fastForward, .playing) == .seek(deltaMs: 30_000))
    }

    @Test func playingBareLeftRightSeek() {
        #expect(command(.none, .left, .playing) == .seek(deltaMs: -10_000))
        #expect(command(.none, .right, .playing) == .seek(deltaMs: 30_000))
    }

    @Test func playingBareDownUpSeekWhenEnabled() {
        let dpad = CatchupSeekKeys(
            rwFf: false, leftRight: false, downUp: true,
            rwLive: false, leftLive: false, downLive: false
        )
        #expect(command(.none, .down, .playing, keys: dpad) == .seek(deltaMs: -10_000))
        #expect(command(.none, .up, .playing, keys: dpad) == .seek(deltaMs: 30_000))
    }

    @Test func playingBareBackReturnsBack() {
        #expect(command(.none, .back, .playing) == .back)
    }

    @Test func leftRightSuppressedOverInfoOverlay() {
        // LEFT/RIGHT seek at bare playback only — the info overlay owns those keys.
        #expect(command(.info, .left, .playing) == nil)
        #expect(command(.info, .right, .playing) == nil)
    }

    @Test func liveCapableRewindRewindsLiveWhenEnabled() {
        let live = CatchupSeekKeys(
            rwFf: false, leftRight: false, downUp: false,
            rwLive: true, leftLive: true, downLive: true
        )
        #expect(command(.info, .rewind, .liveCapable, keys: live) == .rewindLive(deltaMs: 10_000))
        #expect(command(.none, .left, .liveCapable, keys: live) == .rewindLive(deltaMs: 10_000))
        #expect(command(.none, .down, .liveCapable, keys: live) == .rewindLive(deltaMs: 10_000))
    }

    @Test func liveCapableLeftSuppressedOverInfoOverlay() {
        let live = CatchupSeekKeys(
            rwFf: false, leftRight: false, downUp: false,
            rwLive: true, leftLive: true, downLive: true
        )
        #expect(command(.info, .left, .liveCapable, keys: live) == nil)
    }

    @Test func disabledToggleYieldsNil() {
        let off = CatchupSeekKeys(
            rwFf: false, leftRight: false, downUp: false,
            rwLive: false, leftLive: false, downLive: false
        )
        #expect(command(.none, .rewind, .playing, keys: off) == nil)
        #expect(command(.none, .left, .playing, keys: off) == nil)
    }

    @Test func skipOfBuildsFromSteps() {
        let skip = CatchupSkip.of([15, 45])
        #expect(skip.backMs == 15_000)
        #expect(skip.forwardMs == 45_000)
    }

    @Test func skipOfFallsBackForMissingEntries() {
        #expect(CatchupSkip.of([]) == CatchupSkip.defaults)
        #expect(CatchupSkip.of([20]) == CatchupSkip(backMs: 20_000, forwardMs: 20_000))
    }
}
