#if DEBUG
import Testing
@testable import Telly

/// The DEBUG Slice-7 custom-groups screenshot harness's pure logic: the launch-arg
/// flags that select each route, the synthetic fixture's shape, and the seed's
/// persisted playlist / now-airing programmes / pre-created custom groups — all
/// local, never the real provider.
struct DebugLaunchGroupsTests {
    private static let now = 1_700_000_000_000

    @Test func flagsSelectTheirRoutes() {
        #expect(DebugLaunch.manageGroupsRequested(in: ["Telly", "-tellyManageGroups"]))
        #expect(DebugLaunch.manageBlockingRequested(in: ["Telly", "-tellyManageBlocking"]))
        #expect(DebugLaunch.assignEpgRequested(in: ["Telly", "-tellyAssignEpg"]))
        #expect(DebugLaunch.copyChannelsRequested(in: ["Telly", "-tellyCopyChannels"]))
        #expect(DebugLaunch.groupsStripRequested(in: ["Telly", "-tellyGroupsStrip"]))
        #expect(DebugLaunch.groupsSeedPin(in: ["Telly", "-tellySeedPin", "1234"]) == "1234")
        #expect(DebugLaunch.groupsSeedPin(in: ["Telly", "-tellyManageBlocking"]) == nil)
    }

    @Test func groupsDebugRequestedIsTheUnionOfTheRoutes() {
        #expect(DebugLaunch.groupsDebugRequested(in: ["Telly", "-tellyManageGroups"]))
        #expect(DebugLaunch.groupsDebugRequested(in: ["Telly", "-tellyManageBlocking"]))
        #expect(DebugLaunch.groupsDebugRequested(in: ["Telly", "-tellyAssignEpg"]))
        #expect(DebugLaunch.groupsDebugRequested(in: ["Telly", "-tellyCopyChannels"]))
        #expect(DebugLaunch.groupsDebugRequested(in: ["Telly", "-tellyGroupsStrip"]))
        #expect(!DebugLaunch.groupsDebugRequested(in: ["Telly"]))
        #expect(!DebugLaunch.groupsDebugRequested(in: ["Telly", "-tellySearch"]))
    }

    @Test func fixtureHasFourTvgIdChannelsAcrossThreeGroups() {
        let pl = DebugLaunch.groupsFixture()
        #expect(pl.channels.count == 4)
        #expect(pl.channels.compactMap(\.tvgID) == DebugLaunch.groupsEpgIds)
        #expect(Set(pl.channels.compactMap(\.groupTitle))
                == ["Entertainment", "News", "Sports", "Movies"])
        #expect(pl.channels.allSatisfy { $0.streamURL.hasPrefix("http://127.0.0.1:8000/") })
    }

    @Test func epgDocumentIsAiringNowOnTwoChannels() {
        let doc = DebugLaunch.groupsEpgDocument(nowMs: Self.now)
        #expect(doc.programs.count == 2)
        #expect(doc.programs.allSatisfy { $0.startMs <= Self.now && Self.now < $0.endMs })
        #expect(Set(doc.programs.map(\.channelId)) == ["bbc.news", "bbc.one"])
    }

    @Test func seedPersistsPlaylistAndProgrammes() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let programs = ProgramStore(db: db)
        DebugLaunch.seedGroupsFixtures(playlistStore: playlists, programStore: programs,
                                       now: { Self.now })
        #expect(try playlists.all().count == 1)
        #expect(try programs.channelIds() == ["bbc.news", "bbc.one"])
    }

    @Test func seedCustomGroupsCreatesTwoGroupsWithMembership() throws {
        let db = try AppDatabase.makeInMemory()
        let store = CustomGroupStore(db: db)
        DebugLaunch.seedCustomGroups(store: store)
        let groups = try store.all()
        #expect(groups.map(\.name) == ["My Mix", "News Hub"])
        #expect(groups.first { $0.name == DebugLaunch.groupsStripName }?.members
                == ["bbc.one", "sky.sports"])
        #expect(groups.first { $0.name == "News Hub" }?.members == ["bbc.news"])
    }
}
#endif
