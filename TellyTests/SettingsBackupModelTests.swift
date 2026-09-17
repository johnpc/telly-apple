import Testing
import GRDB
@testable import Telly

/// The Backup section's state core over a real manager on an in-memory database:
/// export delegates to the manager; a valid restore applies it and republishes
/// the feed (reload); malformed input reports failure without reloading or
/// crashing. Also round-trips the `FileDocument` string wrapper (iOS/iPad only).
@MainActor
struct SettingsBackupModelTests {
    private func env() -> AppEnvironment {
        AppEnvironment(database: try! AppDatabase.makeInMemory(),
                       settings: SettingsStore(backing: InMemoryKeyValueStore()))
    }

    private func model(_ env: AppEnvironment, reload: @escaping () -> Void) -> SettingsBackupModel {
        SettingsBackupModel(manager: env.makeSettingsBackupManager(), reload: reload)
    }

    @Test func exportDelegatesToManagerAndListsPlaylists() throws {
        let env = env()
        let a = "http://127.0.0.1:8000/a.m3u"
        try env.playlistStore.add(sourceUrl: a, playlist: M3uPlaylist(epgURL: nil, channels: []),
                                  name: "A", nowMs: 0)
        let payload = try #require(BackupCodec.decode(model(env, reload: {}).exportText()))
        #expect(payload.playlists.map(\.url) == [a])
    }

    @Test func restoreAppliesBackupAndReloads() throws {
        let source = env()
        try source.playlistStore.add(sourceUrl: "http://127.0.0.1:8000/a.m3u",
                                     playlist: M3uPlaylist(epgURL: nil, channels: []),
                                     name: "A", nowMs: 0)
        let text = try model(source, reload: {}).exportText()

        let env = env()
        var reloaded = false
        let subject = model(env, reload: { reloaded = true })
        subject.restore(from: text)
        #expect(subject.outcome == .restored)
        #expect(reloaded)
        #expect(try env.playlistStore.all().map(\.url) == ["http://127.0.0.1:8000/a.m3u"])
    }

    @Test func restoreOfMalformedTextReportsFailureWithoutReload() {
        var reloaded = false
        let subject = model(env(), reload: { reloaded = true })
        subject.restore(from: "not json")
        #expect(subject.outcome == .failed)
        #expect(!reloaded)
    }

    #if !os(tvOS)
    @Test func backupDocumentRoundTripsText() {
        #expect(BackupDocument(text: "{\"v\":1}").text == "{\"v\":1}")
    }
    #endif
}
