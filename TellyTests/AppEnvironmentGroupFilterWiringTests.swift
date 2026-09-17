import Testing
import GRDB
@testable import Telly

/// The composition-root wiring for the playlist group filter: disabling a group
/// on one playlist drops only that playlist's channels in that group from the
/// shared visible-channel feed (the helper `makeLivePlaybackModel` reads and the
/// closure both `GuideEpgStore` and `ChannelListModel` are wired with).
@MainActor
struct AppEnvironmentGroupFilterWiringTests {
    private func m(_ name: String, _ group: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func seededEnv() throws -> (AppEnvironment, String) {
        let env = AppEnvironment(database: try AppDatabase.makeInMemory(),
                                 settings: SettingsStore(backing: InMemoryKeyValueStore()))
        let a = "http://127.0.0.1:8000/a.m3u"
        _ = try env.playlistStore.add(sourceUrl: a,
            playlist: M3uPlaylist(channels: [m("A1", "Sport"), m("A2", "News")]), name: nil, nowMs: 0)
        _ = try env.playlistStore.add(sourceUrl: "http://127.0.0.1:8000/b.m3u",
            playlist: M3uPlaylist(channels: [m("B1", "Sport")]), name: nil, nowMs: 0)
        return (env, a)
    }

    @Test func disabledGroupDropsFromFilteredVisibleChannels() throws {
        let (env, a) = try seededEnv()
        #expect(env.filteredVisibleChannels().map(\.source.name).sorted() == ["A1", "A2", "B1"])
        env.settings.setGroupEnabled(url: a, group: "Sport", false)
        // A1 (Sport on playlist A) drops; A2 (News) and B1 (Sport on playlist B) stay.
        #expect(env.filteredVisibleChannels().map(\.source.name).sorted() == ["A2", "B1"])
    }

    @Test func channelListModelSharesTheGroupFilter() throws {
        let (env, a) = try seededEnv()
        env.settings.setGroupEnabled(url: a, group: "Sport", false)
        env.channelListModel.load()
        #expect(env.channelListModel.channels.map(\.source.name).sorted() == ["A2", "B1"])
    }
}
