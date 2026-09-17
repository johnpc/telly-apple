import Testing
@testable import Telly

/// The catch-up transport orchestrator over ``FakePlayerEngine`` and injected
/// neighbour / live-edge fixtures: pause toggle, clamped seek, enter/hop,
/// back→live vs →guide, and Ended→live — every timed decision deterministic,
/// no DB or VLCKit.
@MainActor
struct CatchupPlaybackModelTests {
    private let now = 10_000_000_000
    private let hourMs = 3_600_000

    @MainActor
    final class Harness {
        let engine = FakePlayerEngine()
        var programs: [ProgramEntity] = []
        var airing: ProgramEntity?
        var exitCount = 0
        let now: Int
        init(now: Int) { self.now = now }

        func makeModel() -> CatchupPlaybackModel {
            CatchupPlaybackModel(
                engine: engine,
                neighbours: CatchupNeighbours(programs: { _, _, _ in self.programs }, clock: { self.now }),
                liveEdge: CatchupLiveEdge(
                    nowNext: { _, _ in self.airing.map { NowNext(now: $0, next: nil) } },
                    clock: { self.now }),
                now: { self.now },
                onExitToGuide: { self.exitCount += 1 })
        }
    }

    private func channel() -> ChannelEntity {
        ChannelEntity(
            playlistId: 1, number: 1, sortIndex: 0,
            source: ChannelSource(name: "News", groupTitle: nil, logoUrl: nil,
                                  streamUrl: "http://127.0.0.1/live/news.ts", tvgId: "news.tv"),
            catchup: ChannelCatchup(catchupType: "default",
                                    catchupSource: "http://127.0.0.1/a?utc=${start}&dur=${duration}",
                                    catchupDays: 7))
    }

    private func program(_ start: Int, _ end: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: "news.tv", startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    private func request(start: Int, end: Int, url: String = "http://127.0.0.1/req") -> CatchupRequest {
        CatchupRequest(channel: channel(), url: url, title: "Now", startMs: start, endMs: end)
    }

    // MARK: - Pause

    @Test func togglePauseIsNoOpWithoutState() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.togglePause()
        #expect(harness.engine.paused == false)
        #expect(model.isPaused == false)
    }

    @Test func togglePauseFlipsEngineWhenPlaying() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: now - hourMs, end: now))
        model.togglePause()
        #expect(harness.engine.paused == true)
        #expect(model.isPaused == true)
        model.togglePause()
        #expect(harness.engine.paused == false)
    }

    // MARK: - Seek

    @Test func seekByRecordsClampedTargetAndAdvancesTracker() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: 0, end: 60_000))
        model.seekBy(30_000)
        #expect(harness.engine.seeks == [30_000])
        #expect(model.positionMs == 30_000)
    }

    @Test func seekByClampsToWindowEnds() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: 0, end: 60_000))
        model.seekBy(90_000)
        #expect(model.positionMs == 60_000)
        model.seekBy(-500_000)
        #expect(model.positionMs == 0)
    }

    // MARK: - Enter / mode

    @Test func enterLoadsUrlResetsTrackerAndSetsState() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        #expect(model.mode == .none)
        let req = request(start: now - hourMs, end: now, url: "http://127.0.0.1/archive")
        model.start(req)
        #expect(harness.engine.loaded == ["http://127.0.0.1/archive"])
        #expect(model.positionMs == 0)
        #expect(model.state?.request == req)
        #expect(model.state?.fromLive == false)
        #expect(model.mode == .playing)
        #expect(model.durationMs == hourMs)
    }

    @Test func refreshPositionSamplesEngine() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        harness.engine.positionMs = 12_345
        model.refreshPosition()
        #expect(model.positionMs == 12_345)
    }

    // MARK: - Hop

    @Test func previousEntersNewestEndedNeighbour() {
        let harness = Harness(now: now)
        harness.programs = [program(now - 24 * hourMs, now - 20 * hourMs, "Prev")]
        let model = harness.makeModel()
        model.start(request(start: now - 20 * hourMs, end: now - 18 * hourMs))
        model.previous()
        #expect(model.state?.request.title == "Prev")
    }

    @Test func nextArchiveEntersNeighbour() {
        let harness = Harness(now: now)
        harness.programs = [program(now - 18 * hourMs, now - 16 * hourMs, "Next")]
        let model = harness.makeModel()
        model.start(request(start: now - 20 * hourMs, end: now - 18 * hourMs))
        model.next()
        #expect(model.state?.request.title == "Next")
    }

    @Test func nextLiveReturnsToLiveStream() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: now - 3 * hourMs, end: now - 2 * hourMs))
        model.next()   // no upcoming programme → .live
        #expect(model.state == nil)
        #expect(harness.engine.loaded.last == "http://127.0.0.1/live/news.ts")
    }

    @Test func rewindLiveEntersAiringAndSeeksToOffset() {
        let harness = Harness(now: now)
        harness.airing = program(now - 30 * 60_000, now + 30 * 60_000, "Airing")
        let model = harness.makeModel()
        model.start(request(start: now - hourMs, end: now))
        model.rewindLive(deltaMs: 60_000)
        #expect(model.state?.fromLive == true)
        #expect(model.state?.request.title == "Airing")
        #expect(model.positionMs == 30 * 60_000 - 60_000)   // now-δ-start
    }

    // MARK: - Back / Ended

    @Test func backWithoutFromLiveExitsToGuide() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: now - hourMs, end: now))
        model.back()
        #expect(model.state == nil)
        #expect(harness.exitCount == 1)
    }

    @Test func backFromLiveReturnsToLive() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.enter(request(start: now - hourMs, end: now), fromLive: true)
        model.back()
        #expect(model.state == nil)
        #expect(harness.exitCount == 0)
        #expect(harness.engine.loaded.last == "http://127.0.0.1/live/news.ts")
    }

    @Test func handleEndedReturnsToLiveOnlyWhenEnded() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: now - hourMs, end: now))
        harness.engine.state = .playing
        model.handleEndedIfNeeded()
        #expect(model.state != nil)
        harness.engine.state = .ended
        model.handleEndedIfNeeded()
        #expect(model.state == nil)
        #expect(harness.engine.loaded.last == "http://127.0.0.1/live/news.ts")
    }

    // MARK: - Keys

    @Test func onKeyFastForwardSeeksWhenPlaying() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: 0, end: 120_000))
        #expect(model.onKey(.fastForward, overlay: .none) == true)
        #expect(model.positionMs == 30_000)   // CatchupSkip.defaults.forwardMs
    }

    @Test func onKeyReturnsFalseWhenNoCommand() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        #expect(model.onKey(.fastForward, overlay: .none) == false)   // mode .none
    }

    @Test func onKeyBackExitsAtBarePlayback() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.start(request(start: now - hourMs, end: now))
        #expect(model.onKey(.back, overlay: .none) == true)
        #expect(harness.exitCount == 1)
    }

    // MARK: - Teardown / debug

    @Test func closeStopsAndReleasesEngine() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.close()
        #expect(harness.engine.stopCount == 1)
        #expect(harness.engine.releaseCount == 1)
    }

    @Test func debugOverridesFeedReadout() {
        let harness = Harness(now: now)
        let model = harness.makeModel()
        model.debugPosition = 45_000
        model.debugPaused = true
        #expect(model.positionMs == 45_000)
        #expect(model.isPaused == true)
    }
}
