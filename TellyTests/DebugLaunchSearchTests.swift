#if DEBUG
import Testing
@testable import Telly

/// The DEBUG Slice-8 Search screenshot harness's pure logic: the launch-arg
/// flags that select the two routes, the synthetic fixture's shape, and the
/// seed's persisted playlist / now-airing programmes / recent-query history —
/// all local, never the real provider.
struct DebugLaunchSearchTests {
    private static let now = 1_700_000_000_000

    @Test func flagsSelectTheirRoutes() {
        #expect(DebugLaunch.searchDemoRequested(in: ["Telly", "-tellySearch"]))
        #expect(DebugLaunch.searchResultsQuery(in: ["Telly", "-tellySearchResults", "news"]) == "news")
        #expect(DebugLaunch.searchResultsQuery(in: ["Telly", "-tellySearch"]) == nil)
    }

    @Test func searchDebugRequestedIsTheUnionOfTheRoutes() {
        #expect(DebugLaunch.searchDebugRequested(in: ["Telly", "-tellySearch"]))
        #expect(DebugLaunch.searchDebugRequested(in: ["Telly", "-tellySearchResults", "news"]))
        #expect(!DebugLaunch.searchDebugRequested(in: ["Telly"]))
        #expect(!DebugLaunch.searchDebugRequested(in: ["Telly", "-tellyGuide"]))
    }

    @Test func fixtureHasTwoNewsChannelsAcrossThreeGroups() {
        let pl = DebugLaunch.searchFixture()
        #expect(pl.channels.count == 4)
        #expect(pl.channels.filter { $0.title.localizedCaseInsensitiveContains("news") }.count == 2)
        #expect(Set(pl.channels.compactMap(\.groupTitle)) == ["News", "Sports", "Movies"])
        #expect(pl.channels.allSatisfy { $0.streamURL.hasPrefix("http://127.0.0.1:8000/") })
    }

    @Test func epgDocumentTitlesWordPrefixMatchNewsAndStayInFuture() {
        let doc = DebugLaunch.searchEpgDocument(nowMs: Self.now)
        #expect(doc.programs.count == 3)
        #expect(doc.programs.allSatisfy { $0.endMs > Self.now })
        #expect(doc.programs.allSatisfy { $0.details.title.lowercased().hasPrefix("news") })
        // At least one programme is airing now (channel-shelf now-title + progress).
        #expect(doc.programs.contains { $0.startMs <= Self.now && Self.now < $0.endMs })
    }

    @Test func seedPersistsPlaylistProgrammesAndHistory() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let programs = ProgramStore(db: db)
        let kv = InMemoryKeyValueStore()
        DebugLaunch.seedSearchFixtures(playlistStore: playlists, programStore: programs,
                                       store: kv, now: { Self.now })
        #expect(try playlists.all().count == 1)
        #expect(try programs.channelIds() == [DebugLaunch.searchNewsEpgId, DebugLaunch.searchN24EpgId].sorted())
        #expect(kv.readString("search.history")?.split(separator: "\n").count == DebugLaunch.searchHistorySeed.count)
    }

    @Test func seedIsIdempotentAcrossRelaunches() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let programs = ProgramStore(db: db)
        let kv = InMemoryKeyValueStore()
        for _ in 0..<2 {
            DebugLaunch.seedSearchFixtures(playlistStore: playlists, programStore: programs,
                                           store: kv, now: { Self.now })
        }
        #expect(try playlists.all().count == 1)
        #expect(try programs.channelIds().count == 2)
    }
}
#endif
