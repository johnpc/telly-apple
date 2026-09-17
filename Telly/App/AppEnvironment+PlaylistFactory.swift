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
}
