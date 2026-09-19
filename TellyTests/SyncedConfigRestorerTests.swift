import Testing
@testable import Telly

/// The launch restore decision + orchestration, over spy seams so no Keychain /
/// network is touched. Proves the truth table, that a warranted restore invokes
/// the import path exactly once with the saved URLs, and that a non-empty local
/// DB is never clobbered. Fake `example.com` URLs only.
@MainActor
struct SyncedConfigRestorerTests {
    private static let saved = SyncedConfig(
        playlists: [BackupPlaylist(name: "Home", url: "https://example.com/p.m3u", epgUrl: nil),
                    BackupPlaylist(name: "B", url: "https://example.com/q.m3u", epgUrl: nil)],
        epgSources: [])

    @Test func shouldRestoreTruthTable() {
        #expect(SyncedConfigRestorer.shouldRestore(localEmpty: true, hasSynced: true))
        #expect(!SyncedConfigRestorer.shouldRestore(localEmpty: false, hasSynced: true))
        #expect(!SyncedConfigRestorer.shouldRestore(localEmpty: true, hasSynced: false))
        #expect(!SyncedConfigRestorer.shouldRestore(localEmpty: false, hasSynced: false))
    }

    private final class Spy {
        var recreated: [SyncedConfig] = []
        var reimported: [[String]] = []
    }

    private func restorer(localCount: Int, config: SyncedConfig?, spy: Spy) -> SyncedConfigRestorer {
        SyncedConfigRestorer(
            load: { config },
            localPlaylistCount: { localCount },
            recreate: { spy.recreated.append($0) },
            reimport: { spy.reimported.append($0) })
    }

    @Test func restoresWhenLocalEmptyAndSynced() async {
        let spy = Spy()
        let did = await restorer(localCount: 0, config: Self.saved, spy: spy).restore()
        #expect(did)
        #expect(spy.recreated == [Self.saved])
        #expect(spy.reimported == [["https://example.com/p.m3u", "https://example.com/q.m3u"]])
    }

    @Test func skipsWhenLocalNotEmpty() async {
        let spy = Spy()
        let did = await restorer(localCount: 3, config: Self.saved, spy: spy).restore()
        #expect(!did)
        #expect(spy.recreated.isEmpty)
        #expect(spy.reimported.isEmpty)
    }

    @Test func skipsWhenNothingSynced() async {
        let spy = Spy()
        let did = await restorer(localCount: 0, config: nil, spy: spy).restore()
        #expect(!did)
        #expect(spy.reimported.isEmpty)
    }
}
