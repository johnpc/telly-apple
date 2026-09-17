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

    @Test func fixtureFirstChannelCarriesDemoEpgId() {
        let pl = DebugLaunch.fixturePlaylist(base: "http://127.0.0.1:8000/")
        #expect(pl.channels[0].tvgID == DebugLaunch.demoEpgId)
        #expect(pl.channels[1].tvgID == nil)
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
