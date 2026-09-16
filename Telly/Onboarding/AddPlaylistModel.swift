import Foundation

/// Observable state holder for the add-playlist wizard, ported from the Android
/// `AddPlaylistViewModel`. The UI feeds user intents in; `state` carries the
/// current step, drafts and errors out. The playlist is persisted only when the
/// EPG step's Done is activated. Fetching and the clock are injected, so the
/// whole flow is testable against a fake fetcher and an in-memory database.
@MainActor
@Observable
final class AddPlaylistModel {
    private(set) var state = WizardUiState()

    private let fetch: (String) async throws -> String
    private let store: PlaylistStore
    private let now: () -> Int64
    private var parsed: M3uPlaylist?

    init(fetch: @escaping (String) async throws -> String,
         store: PlaylistStore,
         now: @escaping () -> Int64) {
        self.fetch = fetch
        self.store = store
        self.now = now
    }

    /// Only the M3U path exists in this slice; other types are inert.
    func chooseType(_ type: PlaylistType) {
        if type == .m3u { state.step = .urlEntry }
    }

    func setUrl(_ url: String) { state.url = url; state.error = nil }
    func setName(_ name: String) { state.name = name }
    func setEpgUrl(_ url: String) { state.epgUrl = url; state.error = nil }

    /// "Paste playlist URL" on the EPG step: copies the playlist URL to edit.
    func pastePlaylistUrl() { setEpgUrl(state.url.trimmed) }

    /// Validates the URL (http/https only), then fetches + parses it.
    func submitUrl() async {
        let url = state.url.trimmed
        guard HttpUrl.isValid(url) else { state.error = .invalidURL; return }
        state.step = .processing
        state.error = nil
        do {
            let playlist = M3uParser.parse(try await fetch(url))
            guard state.step == .processing else { return }  // a BACK abandoned it
            showProcessed(url, playlist)
        } catch {
            state.step = .urlEntry
            state.error = .loadFailed
        }
    }

    private func showProcessed(_ url: String, _ playlist: M3uPlaylist) {
        parsed = playlist
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
        _ = try? store.add(sourceUrl: state.url.trimmed, playlist: committed,
                           name: name.isEmpty ? nil : name, nowMs: now())
        state.step = .done
    }

    /// BACK semantics: one step backwards; false means "leave the wizard".
    @discardableResult
    func back() -> Bool {
        switch state.step {
        case .urlEntry: state.step = .typeChooser; state.error = nil
        case .processing: state.step = .urlEntry
        case .processed: parsed = nil; state.step = .urlEntry
        case .epgUrl: state.step = .processed; state.error = nil
        default: return false
        }
        return true
    }
}
