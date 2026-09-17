import Foundation

/// Factories for the playlist-management consumers (update/refresh/backup and
/// the settings model), split into their own extension so the core
/// ``AppEnvironment+Factories`` file stays within its source-line budget. Later
/// playlist slices add their factories here alongside `makePlaylistUpdater`.
extension AppEnvironment {
    /// The manual playlist update core over the real downloader and wall clock;
    /// `PlaylistStore.add` supplies the replace-in-place import semantics.
    func makePlaylistUpdater() -> PlaylistUpdater {
        PlaylistUpdater(fetch: HttpPlaylistFetcher.fetch,
                        store: playlistStore,
                        now: { Int64(Date().timeIntervalSince1970 * 1_000) })
    }

    /// The auto-refresh scheduler over the stored playlists, their per-playlist
    /// interval/on-start settings and the shared clock; each due playlist is
    /// re-imported through a fresh manual updater (Slice-1 `update`).
    func makePlaylistRefresher() -> PlaylistRefresher {
        PlaylistRefresher(playlists: { [playlistStore] in try playlistStore.all() },
                          update: makePlaylistUpdater().update,
                          intervalHours: { [settings] in settings.updateInterval(url: $0) },
                          updateOnStart: { [settings] in settings.updateOnStart(url: $0) },
                          clock: clock)
    }

    /// Launch hook: refresh any playlist due by interval or flagged on-start,
    /// then republish the playlist feed so re-imported channels surface.
    func refreshPlaylistsOnStart() async {
        _ = await makePlaylistRefresher().refreshOnStart()
        reload()
    }

    /// The settings/playlist/EPG-source backup manager over the environment's
    /// real stores and the settings backing store; Slice 6's export/import UI
    /// drives it. Parental-lock state is never included (see ``SettingsSnapshot``).
    func makeSettingsBackupManager() -> SettingsBackupManager {
        SettingsBackupManager(playlistStore: playlistStore, epgSourceStore: epgSourceStore,
                              settings: settings.backing,
                              now: { Int64(Date().timeIntervalSince1970 * 1_000) })
    }

    /// The Backup/Restore section's state core over the manager above; a restore
    /// reloads the playlist feed so re-created playlists surface immediately.
    func makeSettingsBackupModel() -> SettingsBackupModel {
        SettingsBackupModel(manager: makeSettingsBackupManager(),
                            reload: { [weak self] in self?.reload() })
    }

    /// The Playlists management model composing the update/refresh/EPG-source and
    /// per-playlist settings seams; its add flow reuses the wizard `AddPlaylistModel`
    /// and a restore/refresh republishes the playlist feed via `reload`.
    func makePlaylistsSettingsModel() -> PlaylistsSettingsModel {
        PlaylistsSettingsModel(
            playlistStore: playlistStore, epgSourceStore: epgSourceStore,
            channelStore: channelStore, settings: settings, parental: parentalStore,
            updater: makePlaylistUpdater(), makeAddModel: makeAddPlaylistModel,
            refreshEpg: { [weak self] in await self?.refreshEpgNow() },
            reload: { [weak self] in self?.reload() })
    }

    /// The single group-filter wiring both the guide feed and the channel list
    /// route through (built once in `init` and shared) plus the live snapshot:
    /// resolves each channel's playlist URL, then drops channels in groups the
    /// user disabled via the keyed setting. Centralised so the wiring exists once.
    static func groupFiltered(_ channels: [ChannelEntity],
                              playlistStore: PlaylistStore,
                              settings: SettingsStore) -> [ChannelEntity] {
        let index = PlaylistUrlIndex.build((try? playlistStore.all()) ?? [])
        return PlaylistGroupFilter.visible(
            channels, playlistUrlById: index,
            groupEnabled: { settings.groupEnabled(url: $0, group: $1) })
    }

    /// The visible channels with disabled playlist groups removed — the live
    /// player's snapshot seam (`makeLivePlaybackModel`).
    func filteredVisibleChannels() -> [ChannelEntity] {
        Self.groupFiltered((try? channelStore.visibleChannels()) ?? [],
                           playlistStore: playlistStore, settings: settings)
    }
}
