import Foundation

/// Per-playlist auto-refresh policy — the Apple mirror of Android's
/// `PlaylistRefresher`. Decides which stored playlists are due for a re-import
/// (by their configured interval, or an on-start flag) and delegates the actual
/// re-fetch to the injected `update` closure (Slice 1's `PlaylistUpdater`).
/// Every dependency is a seam — the playlist lookup, per-URL settings, the
/// clock and the updater — so the logic runs with no wall clock and no I/O.
struct PlaylistRefresher {
    let playlists: () throws -> [PlaylistEntity]
    let update: (String) async -> Bool
    let intervalHours: (String) -> Int
    let updateOnStart: (String) -> Bool
    let clock: () -> Int

    /// Refreshes every playlist whose configured interval has elapsed,
    /// returning the URLs that refreshed successfully.
    func refreshDue() async -> [String] {
        await refresh { dueByInterval($0) }
    }

    /// Refreshes every playlist flagged update-on-start or already due by
    /// interval — the launch hook. Returns the URLs that refreshed.
    func refreshOnStart() async -> [String] {
        await refresh { updateOnStart($0.url) || dueByInterval($0) }
    }

    /// True when the playlist has a positive interval that has elapsed since its
    /// last update; interval 0 ("None") is never due.
    func dueByInterval(_ playlist: PlaylistEntity) -> Bool {
        let intervalMs = RefreshScheduler.hoursToMs(intervalHours(playlist.url))
        return intervalMs > 0 && RefreshScheduler.isDue(
            lastUpdatedMs: Int(playlist.lastUpdatedMs), nowMs: clock(), intervalMs: intervalMs)
    }

    private func refresh(_ predicate: (PlaylistEntity) -> Bool) async -> [String] {
        let candidates = ((try? playlists()) ?? []).filter(predicate)
        var refreshed: [String] = []
        for playlist in candidates where await update(playlist.url) {
            refreshed.append(playlist.url)
        }
        return refreshed
    }
}
