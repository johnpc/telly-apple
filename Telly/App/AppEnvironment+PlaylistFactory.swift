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
}
