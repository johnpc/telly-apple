import Foundation

/// Launch-time decision + orchestration for restoring the synced provider config
/// after a delete+reinstall (or onto a fresh device). Pure over injected seams so
/// it is fully unit-testable: `load` reads the synced store, `localPlaylistCount`
/// probes the local DB, `recreate` re-creates the empty playlist/EPG records, and
/// `reimport` reuses the SAME wizard import path (fetch + `PlaylistStore.add`) to
/// repopulate channels. The decision never clobbers a non-empty local DB.
@MainActor
struct SyncedConfigRestorer {
    let load: () -> SyncedConfig?
    let localPlaylistCount: () -> Int
    let recreate: (SyncedConfig) -> Void
    let reimport: ([String]) async -> Void

    /// Restore only when the local store is empty (fresh install / new device)
    /// AND the synced store actually has a saved config. Anything else is a no-op
    /// so an existing local library is never overwritten.
    static func shouldRestore(localEmpty: Bool, hasSynced: Bool) -> Bool {
        localEmpty && hasSynced
    }

    /// Runs the restore when warranted: re-creates the records, then re-fetches
    /// each playlist through the wizard import path exactly once. Returns whether
    /// a restore actually happened.
    @discardableResult
    func restore() async -> Bool {
        let config = load()
        guard Self.shouldRestore(localEmpty: localPlaylistCount() == 0, hasSynced: config != nil),
              let config else { return false }
        recreate(config)
        await reimport(config.playlists.map(\.url))
        return true
    }
}
