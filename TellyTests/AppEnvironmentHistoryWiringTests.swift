import Testing
import Foundation
import GRDB
@testable import Telly

/// The composition-root recording seam (Slice B): the `persistLastChannel`
/// closure `makeLivePlaybackModel` builds must, alongside writing `lastChannelId`,
/// resolve the tuned channel and record a `watch_history` row keyed by
/// `ChannelImporter.keyOf`. A cold-start restore records the first channel; a
/// subsequent tune records a second row, newest-first (the shared clock advances).
@MainActor
struct AppEnvironmentHistoryWiringTests {
    private func channel(_ title: String, _ tvgId: String) -> M3uChannel {
        M3uChannel(title: title, streamURL: "http://x/\(tvgId)", tvgID: tvgId, tvgName: nil,
                   tvgLogo: nil, groupTitle: "G", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func seededEnv() throws -> AppEnvironment {
        UserDefaults.standard.removeObject(forKey: "lastChannelId")
        let db = try AppDatabase.makeInMemory()
        var tick = 0
        let env = AppEnvironment(database: db, now: { tick += 1; return tick })
        _ = try env.playlistStore.add(
            sourceUrl: "u",
            playlist: M3uPlaylist(channels: [channel("A", "a"), channel("B", "b")]),
            name: nil, nowMs: 0)
        return env
    }

    @Test func startTuneRecordsRestoredChannel() throws {
        let env = try seededEnv()
        let channels = try env.channelStore.visibleChannels()
        let model = env.makeLivePlaybackModel(engineFactory: { FakePlayerEngine() })
        model.start()

        let rows = try env.watchHistoryStore.recent()
        #expect(rows.count == 1)
        #expect(rows.first?.channelKey == ChannelImporter.keyOf(channels[0]))
    }

    @Test func subsequentTuneRecordsSecondRowNewestFirst() throws {
        let env = try seededEnv()
        let channels = try env.channelStore.visibleChannels()
        let model = env.makeLivePlaybackModel(engineFactory: { FakePlayerEngine() })
        model.start()
        model.tune(channels[1])

        let rows = try env.watchHistoryStore.recent()
        #expect(rows.count == 2)
        #expect(rows.map(\.channelKey) == [ChannelImporter.keyOf(channels[1]),
                                           ChannelImporter.keyOf(channels[0])])
    }
}
