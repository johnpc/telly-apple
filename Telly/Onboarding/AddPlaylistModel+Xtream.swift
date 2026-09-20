import Foundation

/// The Xtream Codes submit path for ``AddPlaylistModel``, split out so the core
/// stays within its source-line budget. Parses the wizard's server/credential
/// drafts, runs the injected import (auth + fetch + map), and hands the resulting
/// ``M3uPlaylist`` to the SAME `showProcessed` → EPG → persist flow as M3U — the
/// playlist is stored under the Xtream `apiUrl`, so refreshes re-run the import.
extension AddPlaylistModel {
    func setServer(_ value: String) { state.server = value; state.error = nil }
    func setUsername(_ value: String) { state.username = value; state.error = nil }
    func setPassword(_ value: String) { state.password = value; state.error = nil }

    /// Validates the drafts into credentials, imports (bounded by the shared
    /// timeout), then summarises. A rejected auth or failed fetch returns to the
    /// Xtream step with `.authFailed`; malformed input shows `.invalidURL`.
    func submitXtream() async {
        guard let creds = XtreamCredentials.parse(
            server: state.server, username: state.username, password: state.password) else {
            state.error = .invalidURL; return
        }
        state.step = .processing
        state.error = nil
        do {
            let playlist = try await loadXtream(creds)
            guard state.step == .processing else { return }  // a BACK abandoned it
            showProcessed(creds.apiUrl, playlist)
        } catch {
            state.step = .xtreamEntry
            state.error = .authFailed
        }
    }

    /// Imports the Xtream account, bounded by ``fetchTimeoutMs`` so a stalled
    /// provider fails into the recoverable error instead of hanging.
    private func loadXtream(_ creds: XtreamCredentials) async throws -> M3uPlaylist {
        let xtream = self.xtream
        return try await withTimeout(milliseconds: Self.fetchTimeoutMs, sleep: sleep) {
            try await xtream(creds)
        }
    }
}
