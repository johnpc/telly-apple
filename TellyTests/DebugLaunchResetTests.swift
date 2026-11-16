#if DEBUG
import Testing
import Foundation
@testable import Telly

/// `-tellyResetState`: the wipe removes the database and its side files, the
/// defaults domain, and the synced config — and only runs when the flag is set.
struct DebugLaunchResetTests {
    @Test func resetRemovesDatabaseDefaultsAndSyncedConfig() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let db = dir.appendingPathComponent("telly.sqlite")
        for suffix in ["", "-wal", "-shm"] { try Data("x".utf8).write(to: URL(fileURLWithPath: db.path + suffix)) }
        let domain = "telly.reset.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defaults.set(42, forKey: "lastChannelId")
        let synced = InMemorySyncedConfigStore()
        synced.save(SyncedConfig(playlists: [BackupPlaylist(name: "a", url: "http://a", epgUrl: nil)], epgSources: []))

        DebugLaunch.resetState(databaseUrl: db, defaults: defaults, domain: domain, synced: synced)

        for suffix in ["", "-wal", "-shm"] { #expect(!FileManager.default.fileExists(atPath: db.path + suffix)) }
        #expect(defaults.object(forKey: "lastChannelId") == nil)
        #expect(synced.load() == nil)
    }

    @Test func flagIsReadByName() {
        #expect(DebugLaunch.resetRequested(in: ["Telly", "-tellyResetState"]))
        #expect(!DebugLaunch.resetRequested(in: ["Telly"]))
    }

    @Test func everyHarnessLaunchResetsUnlessKeepStateIsPassed() {
        #expect(!DebugLaunch.shouldResetState(args: ["Telly"]))                      // a human's plain launch
        #expect(DebugLaunch.shouldResetState(args: ["Telly", "-tellyResetState"]))
        #expect(DebugLaunch.shouldResetState(args: ["Telly", "-tellyDemo"]))
        #expect(DebugLaunch.shouldResetState(args: ["Telly", "-tellyLiveDemo", "-tellyOverlay", "zap"]))
        #expect(!DebugLaunch.shouldResetState(args: ["Telly", "-tellyKeepState"]))
        #expect(!DebugLaunch.shouldResetState(args: ["Telly", "-tellyDemo", "-tellyKeepState"]))
    }
}
#endif
