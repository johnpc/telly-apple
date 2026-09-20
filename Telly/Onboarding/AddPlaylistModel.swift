import Foundation

/// Observable state holder for the add-playlist wizard, ported from the Android
/// `AddPlaylistViewModel`. The UI feeds user intents in; `state` carries the
/// current step, drafts and errors out. The playlist is persisted only when the
/// EPG step's Done is activated. Fetching and the clock are injected, so the
/// whole flow is testable against a fake fetcher and an in-memory database.
@MainActor
@Observable
final class AddPlaylistModel {
    /// Internal setter so the step mutators in `+Back`/`+Xtream` advance it.
    var state = WizardUiState()

    /// The fetch may not outrun this bound — a stall fails into `.loadFailed`.
    static let fetchTimeoutMs = 25_000
    private let fetch: (String) async throws -> String
    private let store: PlaylistStore
    private let now: () -> Int64
    /// Injected timeout clock (deterministic in tests); internal so `+Xtream` reuses it.
    let sleep: @Sendable (UInt64) async throws -> Void
    /// The Xtream import seam (auth + fetch + map); internal so `+Xtream` drives it.
    let xtream: @Sendable (XtreamCredentials) async throws -> M3uPlaylist
    /// Internal so the BACK step machine in `+Back` can clear it.
    var parsed: M3uPlaylist?
    /// The source URL the playlist persists under (M3U URL or Xtream `apiUrl`).
    var importSourceUrl = ""

    init(fetch: @escaping (String) async throws -> String, store: PlaylistStore,
         now: @escaping () -> Int64,
         sleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
         xtream: @escaping @Sendable (XtreamCredentials) async throws -> M3uPlaylist
            = { _ in throw XtreamError.unauthorized }) {
        self.fetch = fetch
        self.store = store
        self.now = now
        self.sleep = sleep
        self.xtream = xtream
    }

    /// Validates the URL (http/https only), then fetches + parses it.
    func submitUrl() async {
        let url = state.url.trimmed
        guard HttpUrl.isValid(url) else { state.error = .invalidURL; return }
        state.step = .processing
        state.error = nil
        do {
            let playlist = M3uParser.parse(try await load(url))
            guard state.step == .processing else { return }  // a BACK abandoned it
            showProcessed(url, playlist)
        } catch {
            state.step = .urlEntry
            state.error = .loadFailed
        }
    }

    /// Fetches `url`, bounded by ``fetchTimeoutMs`` so a stalled request throws a
    /// `TimeoutError` (caught by `submitUrl` as `.loadFailed`) rather than hanging.
    private func load(_ url: String) async throws -> String {
        let fetch = self.fetch
        return try await withTimeout(milliseconds: Self.fetchTimeoutMs, sleep: sleep) {
            try await fetch(url)
        }
    }

    /// Internal so `+Xtream` reuses the processed-summary transition; records the
    /// source ``importSourceUrl`` the playlist will persist under.
    func showProcessed(_ url: String, _ playlist: M3uPlaylist) {
        parsed = playlist
        importSourceUrl = url
        state.step = .processed
        state.name = PlaylistSummary.suggestName(url)
        state.liveCount = PlaylistSummary.liveCount(playlist.channels)
        state.movieCount = PlaylistSummary.movieCount(playlist.channels)
        state.groupCount = PlaylistSummary.groupCount(playlist.channels)
    }

    /// Next on the processed step: forward to the EPG step, pre-filling the
    /// M3U's `url-tvg` into the EPG draft.
    func confirm() {
        guard let playlist = parsed else { return }
        state.epgUrl = playlist.epgURL ?? ""
        state.error = nil
        state.step = .epgUrl
    }

    /// Done on the EPG step: persist the playlist with the (possibly edited)
    /// EPG URL and finish. A blank URL skips the EPG; a non-blank invalid one
    /// reuses the URL-step validation error.
    func finishEpg() async {
        guard let playlist = parsed else { return }
        let epgUrl = state.epgUrl.trimmed
        guard epgUrl.isEmpty || HttpUrl.isValid(epgUrl) else { state.error = .invalidURL; return }
        var committed = playlist
        committed.epgURL = epgUrl.isEmpty ? nil : epgUrl
        let name = state.name.trimmed
        _ = try? store.add(sourceUrl: importSourceUrl, playlist: committed,
                           name: name.isEmpty ? nil : name, nowMs: now())
        state.step = .done
    }
}
