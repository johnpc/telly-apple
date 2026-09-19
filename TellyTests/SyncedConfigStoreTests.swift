import Testing
import Foundation
import Security
@testable import Telly

/// The synced-config store round-trips the JSON blob (via an in-memory secret
/// backing so it needs no real Keychain), the codec is lossless, and the real
/// synchronizable Keychain adapter round-trips against the simulator keychain
/// with a random account per run (never collides, always cleaned up). URLs here
/// are fake `example.com` values — never a real provider token.
struct SyncedConfigStoreTests {
    private static func config() -> SyncedConfig {
        SyncedConfig(
            playlists: [BackupPlaylist(name: "Home", url: "https://example.com/p.m3u",
                                       epgUrl: "https://example.com/e.xml")],
            epgSources: [BackupEpgSource(playlistUrl: "https://example.com/p.m3u",
                                         url: "https://example.com/extra.xml")])
    }

    @Test func codecRoundTrips() throws {
        let text = try #require(Self.config().encoded())
        #expect(SyncedConfig.decode(text) == Self.config())
    }

    @Test func decodeRejectsGarbage() {
        #expect(SyncedConfig.decode("not json") == nil)
    }

    @Test func keychainStoreSaveLoadClear() {
        let store = KeychainSyncedConfigStore(secret: InMemorySecretStore())
        #expect(store.load() == nil)
        store.save(Self.config())
        #expect(store.load() == Self.config())
        store.clear()
        #expect(store.load() == nil)
    }

    @Test func emptyConfigIsEmpty() {
        #expect(SyncedConfig(playlists: [], epgSources: []).isEmpty)
        #expect(!Self.config().isEmpty)
    }

    /// Proves the synchronizable SecItem path compiles and round-trips in-sim.
    /// Uses a random account under a test service and cleans up so it never
    /// pollutes the shared keychain across runs.
    @Test func synchronizableKeychainRoundTrips() {
        let store = KeychainSecretStore(service: "com.johncorser.telly.synced.test",
                                        synchronizable: true,
                                        accessible: kSecAttrAccessibleAfterFirstUnlock)
        let key = "test-\(UUID().uuidString)"
        defer { store.remove(key) }
        #expect(store.read(key) == nil)
        store.write("blob-a", key)
        #expect(store.read(key) == "blob-a")
        store.write("blob-b", key)   // add-or-update path on a synced item
        #expect(store.read(key) == "blob-b")
        store.remove(key)
        #expect(store.read(key) == nil)
    }
}
