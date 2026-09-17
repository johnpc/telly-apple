#if DEBUG
import Testing
@testable import Telly

/// The DEBUG screenshot harness's pure seeding logic: launch-arg parsing, the
/// fixture playlist shape, and the idempotent seed into a real in-memory store.
struct DebugLaunchTests {
    @Test func autoplayUrlReadsTheFlagValue() {
        let args = ["Telly", "-tellyAutoplayUrl", "http://127.0.0.1:8000/news.ts"]
        #expect(DebugLaunch.autoplayUrl(in: args) == "http://127.0.0.1:8000/news.ts")
    }

    @Test func autoplayUrlIsNilWhenFlagAbsent() {
        #expect(DebugLaunch.autoplayUrl(in: ["Telly"]) == nil)
    }

    @Test func autoplayUrlIsNilWhenFlagHasNoValue() {
        #expect(DebugLaunch.autoplayUrl(in: ["Telly", "-tellyAutoplayUrl"]) == nil)
    }

    @Test func fixturePlaylistHasThreeChannelsRootedAtBase() {
        let pl = DebugLaunch.fixturePlaylist(base: "http://127.0.0.1:8000/")
        #expect(pl.epgURL == nil)
        #expect(pl.channels.map(\.title) == ["News HD", "Movie Time", "Dead Channel"])
        #expect(pl.channels.map(\.streamURL) == [
            "http://127.0.0.1:8000/news.ts",
            "http://127.0.0.1:8000/movie.mp4",
            "http://127.0.0.1:8000/dead.ts",
        ])
        #expect(pl.channels.map(\.groupTitle) == ["Live", "VOD", "Live"])
    }

    @Test func seedIfRequestedAddsThePlaylistWhenFlagPresent() throws {
        let db = try AppDatabase.makeInMemory()
        let store = PlaylistStore(db: db)
        DebugLaunch.seedIfRequested(into: store,
                                    args: ["Telly", "-tellySeedBase", "http://127.0.0.1:8000/"],
                                    now: { 42 })
        let stored = try store.all()
        #expect(stored.count == 1)
        #expect(stored[0].name == "Fixtures")
        #expect(stored[0].url == "http://127.0.0.1:8000/playlist.m3u")
        #expect(stored[0].lastUpdatedMs == 42)
    }

    @Test func seedIfRequestedIsANoOpWithoutTheFlag() throws {
        let db = try AppDatabase.makeInMemory()
        let store = PlaylistStore(db: db)
        DebugLaunch.seedIfRequested(into: store, args: ["Telly"], now: { 0 })
        #expect(try store.all().isEmpty)
    }

    @Test func liveDemoRequestedReadsFlag() {
        #expect(DebugLaunch.liveDemoRequested(in: ["Telly", "-tellyLiveDemo"]))
        #expect(!DebugLaunch.liveDemoRequested(in: ["Telly"]))
    }

    @Test func forcedZapOverlayReadsFlag() {
        #expect(DebugLaunch.forcedZapOverlay(in: ["Telly", "-tellyOverlay", "zap"]))
        #expect(!DebugLaunch.forcedZapOverlay(in: ["Telly", "-tellyOverlay", "info"]))
        #expect(!DebugLaunch.forcedZapOverlay(in: ["Telly"]))
    }

    @Test func forcedInfoOverlayReadsFlag() {
        #expect(DebugLaunch.forcedInfoOverlay(in: ["Telly", "-tellyOverlay", "info"]))
        #expect(!DebugLaunch.forcedInfoOverlay(in: ["Telly", "-tellyOverlay", "zap"]))
        #expect(!DebugLaunch.forcedInfoOverlay(in: ["Telly"]))
    }

    @Test func forcedQuickBarOverlayReadsFlag() {
        #expect(DebugLaunch.forcedQuickBarOverlay(in: ["Telly", "-tellyOverlay", "quickBar"]))
        #expect(!DebugLaunch.forcedQuickBarOverlay(in: ["Telly", "-tellyOverlay", "zap"]))
        #expect(!DebugLaunch.forcedQuickBarOverlay(in: ["Telly"]))
    }

    @Test func forcedPanelOverlayReadsFlag() {
        #expect(DebugLaunch.forcedPanelOverlay(in: ["Telly", "-tellyOverlay", "panel"]))
        #expect(!DebugLaunch.forcedPanelOverlay(in: ["Telly", "-tellyOverlay", "quickBar"]))
        #expect(!DebugLaunch.forcedPanelOverlay(in: ["Telly"]))
    }

    @Test func fixtureChannelsCarryEpgIds() {
        let pl = DebugLaunch.fixturePlaylist(base: "http://127.0.0.1:8000/")
        #expect(pl.channels[0].tvgID == DebugLaunch.demoEpgId)
        #expect(pl.channels[1].tvgID == DebugLaunch.moviesEpgId)
        #expect(pl.channels[2].tvgID == "sports.tv")
    }

    @Test func forcedGuideReadsFlag() {
        #expect(DebugLaunch.forcedGuide(in: ["Telly", "-tellyGuide"]))
        #expect(!DebugLaunch.forcedGuide(in: ["Telly"]))
        #expect(!DebugLaunch.forcedGuide(in: ["Telly", "-tellyOverlay"]))
    }

    // A realistic epoch (≈2023) so `halfHourFloor` in the device time-zone stays
    // well-defined regardless of the machine's zone (small values can go negative).
    private static let realisticNow = 1_700_000_000_000

    @Test func guideEpgDocumentSeedsBackToBackTitledStrips() {
        let doc = DebugLaunch.guideEpgDocument(nowMs: Self.realisticNow)
        #expect(doc.programs.count == 8)
        let news = doc.programs.filter { $0.channelId == DebugLaunch.demoEpgId }
        #expect(news.map(\.details.title) == ["Morning News", "Midday Report", "Evening News", "Night Desk"])
        // Contiguous: each programme starts where the previous ended.
        #expect(zip(news, news.dropFirst()).allSatisfy { $0.endMs == $1.startMs })
        // "now" falls inside the second (titled) cell of each strip.
        let nowCell = news.first { $0.startMs <= Self.realisticNow && Self.realisticNow < $0.endMs }
        #expect(nowCell?.details.title == "Midday Report")
    }

    @Test func seedGuideEpgWritesProgrammesWhenFlagPresent() throws {
        let db = try AppDatabase.makeInMemory()
        let store = ProgramStore(db: db)
        DebugLaunch.seedGuideEpg(into: store, args: ["Telly", "-tellyGuide"],
                                 now: { Self.realisticNow })
        #expect(try store.window(tvgIds: [DebugLaunch.demoEpgId, DebugLaunch.moviesEpgId],
                                 fromMs: 0, toMs: Self.realisticNow + 20_000_000).count == 8)
    }

    @Test func seedGuideEpgIsANoOpWithoutTheFlag() throws {
        let db = try AppDatabase.makeInMemory()
        let store = ProgramStore(db: db)
        DebugLaunch.seedGuideEpg(into: store, args: ["Telly"], now: { Self.realisticNow })
        #expect(try store.channelIds().isEmpty)
    }

    @Test func infoFixtureDocumentSeedsNowAndNextOnDemoChannel() {
        let doc = DebugLaunch.infoFixtureDocument(nowMs: 10_000_000)
        #expect(doc.programs.count == 2)
        #expect(doc.programs.allSatisfy { $0.channelId == DebugLaunch.demoEpgId })
        let now = NowNextResolver.resolve(doc.programs.map {
            ProgramEntity(channelTvgId: $0.channelId, startMs: $0.startMs,
                          endMs: $0.endMs, details: $0.details)
        }, atMs: 10_000_000)[DebugLaunch.demoEpgId]
        #expect(now?.now?.details.title == "Evening News")
        #expect(now?.next?.details.title == "Late Documentary")
    }
}
#endif
