import Foundation

/// Pure policy deciding whether a completed playlist update should force an EPG
/// refresh — the Apple mirror of Android's `EpgRefresher.onPlaylistsChanged`.
/// With the app-wide "Update on playlists change" toggle ON, a successful
/// playlist change triggers a refresh; OFF (or when nothing actually changed)
/// the refresh is skipped. Kept as a free-standing tested seam so the decision
/// never hides untested inside a view or `@Observable`.
enum EpgRefreshPolicy {
    /// True iff an EPG refresh should run after a playlist update completed.
    /// - Parameters:
    ///   - anyUpdated: whether at least one playlist was re-imported.
    ///   - updateOnChange: the app-wide "Update on playlists change" toggle.
    static func shouldRefreshAfterPlaylistUpdate(anyUpdated: Bool, updateOnChange: Bool) -> Bool {
        anyUpdated && updateOnChange
    }
}
