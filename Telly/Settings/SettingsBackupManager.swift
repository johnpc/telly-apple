import Foundation

/// Composes the pure backup codec/snapshot with the persistence stores to
/// export a full settings + playlist + custom-EPG-source backup and restore
/// one — the Apple mirror of Android's `SettingsBackupManager`. This is the
/// seam Slice 6's `FileDocument` export/import UI drives. Restore re-creates
/// each playlist with ZERO channels (a subsequent "Update playlist" re-fetches
/// them, matching Android) and re-attaches its custom EPG sources.
@MainActor
struct SettingsBackupManager {
    let playlistStore: PlaylistStore
    let epgSourceStore: EpgSourceStore
    let settings: KeyValueStore
    let now: () -> Int64

    /// Serialises the current settings, playlists and custom EPG sources to
    /// pretty-printed backup JSON.
    func exportJson() throws -> String {
        let playlists = try playlistStore.all().map {
            BackupPlaylist(name: $0.name, url: $0.url, epgUrl: $0.epgUrl)
        }
        let sources = try epgSourceStore.all().map {
            BackupEpgSource(playlistUrl: $0.playlistUrl, url: $0.url)
        }
        return BackupCodec.encode(BackupPayload(
            settings: SettingsSnapshot.snapshot(from: settings),
            playlists: playlists, epgSources: sources))
    }

    /// Restores a backup: applies its settings, then re-creates each playlist
    /// (zero channels) and its custom EPG sources. Returns false on malformed
    /// JSON, leaving the current state untouched.
    @discardableResult
    func importJson(_ text: String) throws -> Bool {
        guard let payload = BackupCodec.decode(text) else { return false }
        SettingsSnapshot.restore(payload.settings, into: settings)
        for playlist in payload.playlists {
            try playlistStore.add(sourceUrl: playlist.url,
                                  playlist: M3uPlaylist(epgURL: playlist.epgUrl, channels: []),
                                  name: playlist.name, nowMs: now())
        }
        for source in payload.epgSources {
            try epgSourceStore.add(playlistUrl: source.playlistUrl, url: source.url, nowMs: now())
        }
        return true
    }
}
