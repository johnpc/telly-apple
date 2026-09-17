import Testing
import GRDB
@testable import Telly

/// The composition-root wiring for backup: `makeSettingsBackupManager` must
/// build a manager over the environment's real stores and settings backing, so
/// an export/import round-trip lands against the same in-memory database and
/// key-value store the environment exposes.
@MainActor
struct AppEnvironmentBackupWiringTests {
    @Test func makeSettingsBackupManagerRoundTripsThroughEnvironmentStores() throws {
        let env = AppEnvironment(database: try AppDatabase.makeInMemory(),
                                 settings: SettingsStore(backing: InMemoryKeyValueStore()))
        let a = "http://127.0.0.1:8000/a.m3u"
        try env.playlistStore.add(sourceUrl: a, playlist: M3uPlaylist(epgURL: nil, channels: []),
                                  name: "A", nowMs: 0)
        env.settings.epgRefreshHours = 6
        let manager = env.makeSettingsBackupManager()
        let payload = try #require(BackupCodec.decode(try manager.exportJson()))
        #expect(payload.playlists.map(\.url) == [a])
        #expect(payload.settings[SettingsKey.epgRefreshHours.rawValue] == "6")
        #expect(try manager.importJson(BackupCodec.encode(payload)))
        #expect(try env.playlistStore.all().map(\.url) == [a])
    }
}
