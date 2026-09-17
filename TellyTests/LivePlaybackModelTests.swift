import Testing
@testable import Telly

/// The live orchestrator's dispatch, coalesced zap→tune, auto-hide, keep-frame,
/// restore-on-start and teardown — composed over ``FakePlayerEngine`` and a
/// manual integer clock so every timed decision is deterministic.
@MainActor
struct LivePlaybackModelTests {
    /// Per-test mutable seams: the clock, the persist/exit spies and the fake
    /// engine, all captured by the model's injected closures.
    @MainActor
    final class Harness {
        let engine = FakePlayerEngine()
        var clock = 0
        var persisted: [Int] = []
        var exitCount = 0
        var stored: Int?

        func makeModel(_ channels: [ChannelEntity]) -> LivePlaybackModel {
            LivePlaybackModel(
                engine: engine,
                channels: channels,
                now: { self.clock },
                persistLastChannel: { self.persisted.append($0) },
                loadLastChannel: { self.stored },
                onExitToGuide: { self.exitCount += 1 })
        }
    }

    private func ch(_ id: Int, _ number: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: number, sortIndex: number,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }
    private var channels: [ChannelEntity] { [ch(10, 1), ch(20, 2), ch(30, 3)] }

    // MARK: - Key dispatch

    @Test func okShowsInfoOverlay() {
        let model = Harness().makeModel(channels)
        #expect(model.onKey(.ok) == true)
        #expect(model.overlay == .info)
    }

    @Test func secondUpExpandsTransport() {
        let model = Harness().makeModel(channels)
        _ = model.onKey(.up)
        #expect(model.overlay == .info)
        _ = model.onKey(.up)
        #expect(model.overlay == .infoTransport)
    }

    @Test func menuOpensQuickBar() {
        let model = Harness().makeModel(channels)
        _ = model.onKey(.menu)
        #expect(model.overlay == .quickBar)
    }

    @Test func backAtBarePlaybackExitsToGuide() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        #expect(model.onKey(.back) == true)
        #expect(harness.exitCount == 1)
        #expect(model.overlay == .none)
    }

    @Test func downThenDownOpensPanel() {
        let model = Harness().makeModel(channels)
        _ = model.onKey(.down)          // bare → info
        _ = model.onKey(.down)          // within info → panel
        #expect(model.overlay == .panel)
    }

    @Test func dismissWithinQuickBar() {
        let model = Harness().makeModel(channels)
        _ = model.onKey(.menu)
        #expect(model.overlay == .quickBar)
        #expect(model.onKey(.back) == true)
        #expect(model.overlay == .none)
    }

    @Test func unboundKeyReturnsFalseAndKeepsOverlay() {
        let model = Harness().makeModel(channels)
        _ = model.onKey(.menu)
        #expect(model.onKey(.right) == false)   // right is inert (leftRight = .nothing)
        #expect(model.overlay == .quickBar)
    }

    @Test func executeCoversRemainingArms() {
        let model = Harness().makeModel(channels)
        model.execute(.showTransport)
        #expect(model.overlay == .infoTransport)
        model.execute(.backToPanel)
        #expect(model.overlay == .panel)
        model.execute(.popTo(.info))
        #expect(model.overlay == .info)
        model.execute(.nothing)
        #expect(model.overlay == .info)         // no-op leaves it untouched
        model.execute(.dismiss)
        #expect(model.overlay == .none)
    }

    // MARK: - Zap → tune (coalesced)

    @Test func channelUpArmsPendingZapAndShowsZapOverlay() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        #expect(model.onKey(.channelUp) == true)
        #expect(model.overlay == .zapInfo)
        #expect(harness.engine.loaded.isEmpty)   // no tune yet — only armed
        #expect(model.current == nil)
    }

    @Test func tickAfterSettleTunesNeighbour() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()                            // current = ch10
        _ = model.onKey(.channelUp)              // press +1 at t=0 (deadline 250)
        harness.clock = 300
        model.tick()                             // settled → tune ch20
        #expect(model.current?.id == 20)
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts", "http://127.0.0.1/20.ts"])
        #expect(harness.persisted == [10, 20])
    }

    @Test func rapidUpUpTunesOnceToNetNeighbour() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()
        harness.clock = 0;  _ = model.onKey(.channelUp)
        harness.clock = 50; _ = model.onKey(.channelUp)
        harness.clock = 400
        model.tick()
        #expect(model.current?.id == 30)         // +2 from ch10
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts", "http://127.0.0.1/30.ts"])
        #expect(harness.persisted == [10, 30])   // exactly one tune
    }

    @Test func netZeroZapSkipsTune() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()
        harness.clock = 0;  _ = model.onKey(.channelUp)
        harness.clock = 50; _ = model.onKey(.channelDown)
        harness.clock = 400
        model.tick()
        #expect(model.current?.id == 10)
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts"])
        #expect(model.overlay == .zapInfo)       // overlay stayed up
    }

    // MARK: - Auto-hide

    @Test func zapOverlayExpiresAtZapTimeout() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()
        _ = model.onKey(.channelUp)              // zapInfo, deadline t+5500
        harness.clock = 5_500
        model.tick()
        #expect(model.overlay == .none)
    }

    @Test func keepAliveOnKeyExtendsOverlay() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        _ = model.onKey(.channelUp)              // zapInfo at t=0, deadline 5500
        harness.clock = 5_000
        _ = model.onKey(.right)                  // inert, but keepAlive re-arms → 10500
        harness.clock = 5_600
        model.tick()
        #expect(model.overlay == .zapInfo)       // would have expired without keepAlive
    }

    // MARK: - Keep-frame

    @Test func holdsLastFrameWhileBufferingAfterZap() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()
        _ = model.onKey(.channelUp)
        harness.clock = 300
        model.tick()                             // tune ch20 → keep-frame armed
        harness.engine.state = .buffering
        harness.clock = 400
        #expect(model.holdsLastFrame == true)
    }

    @Test func tickClearsHoldWhenPlaying() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()
        _ = model.onKey(.channelUp)
        harness.clock = 300
        model.tick()
        harness.engine.state = .playing
        harness.clock = 500
        model.tick()                             // onPlaying clears the hold
        harness.engine.state = .buffering
        #expect(model.holdsLastFrame == false)
    }

    // MARK: - Restore on start / teardown

    @Test func startTunesRestoredLastChannel() {
        let harness = Harness()
        harness.stored = 20
        let model = harness.makeModel(channels)
        model.start()
        #expect(model.current?.id == 20)
        #expect(harness.engine.loaded == ["http://127.0.0.1/20.ts"])
        #expect(harness.persisted == [20])
        #expect(model.overlay == .none)          // silent — no zap overlay
    }

    @Test func startFallsBackToFirstWhenNoStored() {
        let harness = Harness()
        harness.stored = nil
        let model = harness.makeModel(channels)
        model.start()
        #expect(model.current?.id == 10)
        #expect(harness.engine.loaded == ["http://127.0.0.1/10.ts"])
    }

    @Test func startWithNoChannelsTunesNothing() {
        let harness = Harness()
        let model = harness.makeModel([])
        model.start()
        #expect(model.current == nil)
        #expect(harness.engine.loaded.isEmpty)
    }

    @Test func closeStopsAndReleasesEngine() {
        let harness = Harness()
        let model = harness.makeModel(channels)
        model.close()
        #expect(harness.engine.stopCount == 1)
        #expect(harness.engine.releaseCount == 1)
    }

    @Test func debugPresentZapOverlayPinsOverlayAndHoldsFrame() {
        let model = Harness().makeModel(channels)
        model.debugPresentZapOverlay()
        #expect(model.overlay == .zapInfo)
        #expect(model.holdsLastFrame == true)    // held regardless of engine state
    }

    @Test func debugPresentInfoOverlayPinsOverlayAndHoldsFrame() {
        let model = Harness().makeModel(channels)
        model.debugPresentInfoOverlay()
        #expect(model.overlay == .info)
        #expect(model.holdsLastFrame == true)
    }

    // MARK: - EPG now/next seam

    @Test func currentInfoIsNilWithDefaultSeam() {
        let harness = Harness()
        harness.stored = 10
        let model = harness.makeModel(channels)
        model.start()
        #expect(model.currentInfo == nil)        // default seam yields no data
    }

    @Test func currentInfoReadsSeamForTunedChannel() {
        let harness = Harness()
        harness.stored = 10
        let feed = NowNext(now: ProgramEntity(channelTvgId: "10", startMs: 0, endMs: 100,
                                              details: ProgramDetails(title: "On Now")), next: nil)
        let model = LivePlaybackModel(
            engine: harness.engine, channels: channels,
            now: { harness.clock },
            persistLastChannel: { harness.persisted.append($0) },
            loadLastChannel: { harness.stored },
            onExitToGuide: {},
            nowNext: { $0.id == 10 ? feed : nil })
        model.start()
        #expect(model.currentInfo?.now?.details.title == "On Now")
    }
}
