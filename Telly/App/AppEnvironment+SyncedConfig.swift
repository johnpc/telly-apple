import Foundation

/// Cross-reinstall / cross-device config persistence wiring, split out of the
/// composition root so no capped file grows. Write-through mirrors the current
/// playlist + EPG config into the synchronizable Keychain on every user
/// mutation; the launch restorer brings it back when the local DB is empty,
/// re-fetching channels through the same import path the add-playlist wizard uses.
extension AppEnvironment {
    /// The current provider config derived from the local stores.
    func currentSyncedConfig() -> SyncedConfig {
        let playlists = ((try? playlistStore.all()) ?? []).map {
            BackupPlaylist(name: $0.name, url: $0.url, epgUrl: $0.epgUrl)
        }
        let sources = ((try? epgSourceStore.all()) ?? []).map {
            BackupEpgSource(playlistUrl: $0.playlistUrl, url: $0.url)
        }
        return SyncedConfig(playlists: playlists, epgSources: sources)
    }

    /// Write-through hook: mirror the current config into the synced store, or
    /// clear it when the user has removed their last playlist. Called from the
    /// same seams playlist / EPG-source mutations go through.
    func mirrorSyncedConfig() {
        let config = currentSyncedConfig()
        if config.isEmpty { syncedConfigStore.clear() } else { syncedConfigStore.save(config) }
    }

    /// Re-creates the restored records (empty playlists + their custom EPG
    /// sources), mirroring `SettingsBackupManager.importJson`; a later re-fetch
    /// lands the channels.
    func recreate(from config: SyncedConfig) {
        for playlist in config.playlists {
            _ = try? playlistStore.add(sourceUrl: playlist.url,
                                       playlist: M3uPlaylist(epgURL: playlist.epgUrl, channels: []),
                                       name: playlist.name, nowMs: Int64(clock()))
        }
        for source in config.epgSources {
            try? epgSourceStore.add(playlistUrl: source.playlistUrl, url: source.url, nowMs: Int64(clock()))
        }
    }

    /// The restorer wired to the real seams: reuses `makePlaylistUpdater` (the
    /// wizard import path) to re-fetch channels after re-creating the records.
    func makeSyncedConfigRestorer() -> SyncedConfigRestorer {
        SyncedConfigRestorer(
            load: { [syncedConfigStore] in syncedConfigStore.load() },
            localPlaylistCount: { [playlistStore] in ((try? playlistStore.all()) ?? []).count },
            recreate: { [weak self] in self?.recreate(from: $0) },
            reimport: { [weak self] urls in
                guard let self else { return }
                _ = await self.makePlaylistUpdater().updateAll(urls)
                self.reload()
                await self.refreshEpgNow()
                self.channelListModel.load()
            })
    }

    /// Launch hook: restore the synced config when the local DB is empty.
    func restoreSyncedConfigIfNeeded() async {
        await makeSyncedConfigRestorer().restore()
    }
}
