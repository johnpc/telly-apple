import Foundation

/// The search screen's observable state (catalogue §4): live results per query
/// change, the landing history list, the Programs master-lane selection and its
/// focused airing, and the tune target that drives the player cover. The Apple
/// mirror of Android's `SearchViewModel` — voice and the programme dropdown are
/// out of scope, so results recompute synchronously over local GRDB (no timed
/// debounce) and a Programs row simply tunes its channel.
@MainActor
@Observable
final class SearchModel {
    let repository: SearchRepository
    let history: SearchHistory
    let now: () -> Int
    let timeZone: TimeZone

    var query: String = ""
    private(set) var results = SearchResults()
    private(set) var historyEntries: [String] = []
    /// The Programs master-lane channel whose airings the rows pane shows.
    private(set) var selectedChannel: SearchProgramChannel?
    /// Feeds the right-side detail card (the selected channel's focused airing).
    private(set) var focusedProgram: SearchProgramHit?
    /// Non-nil launches the fullscreen player at the tuned channel's stream.
    var tuneTarget: SearchTuneTarget?

    init(repository: SearchRepository, history: SearchHistory,
         now: @escaping () -> Int, timeZone: TimeZone) {
        self.repository = repository
        self.history = history
        self.now = now
        self.timeZone = timeZone
    }

    /// Reads the persisted recent queries into the landing list (called on appear).
    func load() { historyEntries = history.list() }

    /// Recomputes results for the current query and preselects the first
    /// master-lane channel and its first airing; an empty query clears both
    /// (the repository returns empty results, so selection resolves to nil).
    func search() {
        results = (try? repository.search(query, atMs: now(), timeZone: timeZone)) ?? SearchResults()
        selectedChannel = results.programs.first
        focusedProgram = selectedChannel?.airings.first
    }

    /// Commits the current query into the history (IME search / result OK).
    func commit() {
        history.record(query)
        historyEntries = history.list()
    }

    /// Tapping a history entry adopts it as the query, recomputes and commits.
    func onHistoryEntry(_ entry: String) {
        query = entry
        search()
        commit()
    }

    /// Clears the whole recent-query list (the header's trash affordance).
    func clearHistory() {
        history.clear()
        historyEntries = []
    }

    /// OK on a channel card tunes its stream and commits the query.
    func onChannelResult(_ hit: SearchChannelHit) { tune(hit.channel) }

    /// OK on a Programs master card tunes its channel — programme rows just tune,
    /// no dropdown (the free reference gated this behind premium; telly removed it).
    func onProgramChannelResult(_ channel: SearchProgramChannel) { tune(channel.channel) }

    /// Focusing an airing row swaps the detail card to that programme.
    func onProgramFocused(_ hit: SearchProgramHit) { focusedProgram = hit }

    /// Focusing a master card swaps the rows pane to that channel's airings and
    /// preselects its first airing into the detail card.
    func onProgramChannelFocused(_ channel: SearchProgramChannel) {
        selectedChannel = channel
        focusedProgram = channel.airings.first
    }

    private func tune(_ channel: ChannelEntity) {
        tuneTarget = SearchTuneTarget(url: channel.source.streamUrl)
        commit()
    }
}

/// Identifies the channel a search result tunes to (drives the fullscreen cover),
/// keyed by its stream URL — the sibling of History's inline playback target.
struct SearchTuneTarget: Identifiable {
    let url: String
    var id: String { url }
}
