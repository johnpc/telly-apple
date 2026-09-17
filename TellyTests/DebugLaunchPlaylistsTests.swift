#if DEBUG
import Testing
@testable import Telly

/// The DEBUG Slice-9 playlist/settings screenshot harness's pure logic: the
/// launch-arg flags that select each Settings pane, and the synthetic seed's
/// fixture shape (two `127.0.0.1` playlists across named groups, one with an
/// auto `url-tvg`) — all local, never the real provider.
struct DebugLaunchPlaylistsTests {
    @Test func flagsSelectTheirPanes() {
        #expect(DebugLaunch.playlistsDemoRequested(in: ["Telly", "-tellyPlaylists"]))
        #expect(DebugLaunch.playlistDetailRequested(in: ["Telly", "-tellyPlaylistDetail"]))
        #expect(DebugLaunch.epgSourcesRequested(in: ["Telly", "-tellyEpgSources"]))
        #expect(DebugLaunch.playlistGroupsRequested(in: ["Telly", "-tellyPlaylistGroups"]))
        #expect(DebugLaunch.backupRequested(in: ["Telly", "-tellyBackup"]))
        #expect(DebugLaunch.appearanceRequested(in: ["Telly", "-tellyAppearance"]))
    }

    @Test func playlistDebugRequestedIsTheUnionOfTheRoutes() {
        #expect(DebugLaunch.playlistDebugRequested(in: ["Telly", "-tellyBackup"]))
        #expect(DebugLaunch.playlistDebugRequested(in: ["Telly", "-tellyPlaylists"]))
        #expect(!DebugLaunch.playlistDebugRequested(in: ["Telly"]))
        #expect(!DebugLaunch.playlistDebugRequested(in: ["Telly", "-tellyGuide"]))
    }

    @Test func primaryFixtureHasAutoEpgAndThreeGroups() {
        let pl = DebugLaunch.primaryFixture()
        #expect(pl.epgURL == "http://127.0.0.1:8000/a/epg.xml")
        #expect(pl.channels.count == 3)
        #expect(Set(pl.channels.compactMap(\.groupTitle)) == ["News", "Sports", "Movies"])
        #expect(pl.channels.allSatisfy { $0.streamURL.hasPrefix("http://127.0.0.1:8000/") })
    }

    @Test func secondaryFixtureHasNoAutoEpgAndTwoGroups() {
        let pl = DebugLaunch.secondaryFixture()
        #expect(pl.epgURL == nil)
        #expect(Set(pl.channels.compactMap(\.groupTitle)) == ["Kids", "Music"])
    }

    @Test func seedPersistsBothPlaylistsAndOneCustomSource() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let sources = EpgSourceStore(db: db)
        DebugLaunch.seedPlaylistFixtures(playlistStore: playlists,
                                         epgSourceStore: sources, now: { 1_700_000_000_000 })
        #expect(try playlists.all().count == 2)
        let custom = try sources.forPlaylist(DebugLaunch.demoPlaylistUrl)
        #expect(custom.count == 1)
        #expect(custom[0].url == "http://127.0.0.1:8000/a/epg-extra.xml")
    }

    @Test func seedIsIdempotentAcrossRelaunches() throws {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let sources = EpgSourceStore(db: db)
        for _ in 0..<2 {
            DebugLaunch.seedPlaylistFixtures(playlistStore: playlists,
                                             epgSourceStore: sources, now: { 1_700_000_000_000 })
        }
        #expect(try playlists.all().count == 2)
        #expect(try sources.forPlaylist(DebugLaunch.demoPlaylistUrl).count == 1)
    }
}
#endif
