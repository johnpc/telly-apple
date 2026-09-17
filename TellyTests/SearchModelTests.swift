import Foundation
import Testing
import GRDB
@testable import Telly

/// `SearchModel` (Android `SearchViewModel`, minus voice + the programme
/// dropdown): a query change recomputes results over a real in-memory
/// `SearchRepository` and preselects the first Programs master channel and its
/// first airing; commit / history-entry flow queries through a fake-store
/// `SearchHistory`; a channel or master-card result tunes the stream and
/// commits. Fixed clock + UTC keep it deterministic.
@MainActor
struct SearchModelTests {
    private static let atMs = 1_000
    private let utc = TimeZone(identifier: "UTC")!

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ tvgId: String, _ start: Int, _ end: Int, title: String) -> XmltvProgram {
        XmltvProgram(channelId: tvgId, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    private func makeModel(store: KeyValueStore = InMemoryKeyValueStore()) throws -> SearchModel {
        let db = try AppDatabase.makeInMemory()
        _ = try PlaylistStore(db: db).add(sourceUrl: "u",
                                          playlist: M3uPlaylist(channels: [m("News"), m("Sports")]),
                                          name: nil, nowMs: 0)
        let programStore = ProgramStore(db: db)
        try programStore.upsertReplacing(
            document: XmltvDocument(channels: [], programs: [prog("News", 900, 1_500, title: "News Live")]),
            keepDescriptions: true)
        let repo = SearchRepository(channelStore: ChannelStore(db: db), programStore: programStore,
                                    epg: EpgRepository(store: programStore))
        return SearchModel(repository: repo, history: SearchHistory(store: store),
                           now: { Self.atMs }, timeZone: utc)
    }

    @Test func searchRecomputesAndPreselectsFirstProgramChannelAndAiring() throws {
        let model = try makeModel()
        model.query = "news"
        model.search()
        #expect(model.results.channels.map { $0.channel.source.name } == ["News"])
        #expect(model.selectedChannel?.channel.source.name == "News")
        #expect(model.focusedProgram?.title == "News Live")
    }

    @Test func emptyQueryClearsResultsAndSelection() throws {
        let model = try makeModel()
        model.query = "news"
        model.search()
        model.query = "   "
        model.search()
        #expect(model.results.isEmpty)
        #expect(model.selectedChannel == nil)
        #expect(model.focusedProgram == nil)
    }

    @Test func commitRecordsQueryAndRefreshesHistory() throws {
        let store = InMemoryKeyValueStore()
        let model = try makeModel(store: store)
        model.query = "news"
        model.commit()
        #expect(model.historyEntries == ["news"])
        // Dedup/cap is delegated to SearchHistory — re-committing keeps one entry.
        model.commit()
        #expect(model.historyEntries == ["news"])
    }

    @Test func onHistoryEntrySetsQueryRecomputesAndCommits() throws {
        let model = try makeModel()
        model.onHistoryEntry("news")
        #expect(model.query == "news")
        #expect(model.selectedChannel?.channel.source.name == "News")
        #expect(model.historyEntries == ["news"])
    }

    @Test func clearHistoryEmptiesEntries() throws {
        let model = try makeModel()
        model.onHistoryEntry("news")
        #expect(!model.historyEntries.isEmpty)
        model.clearHistory()
        #expect(model.historyEntries.isEmpty)
    }

    @Test func onChannelResultTunesStreamAndCommits() throws {
        let model = try makeModel()
        model.query = "news"
        model.search()
        model.onChannelResult(model.results.channels[0])
        #expect(model.tuneTarget?.url == "http://x/News")
        #expect(model.historyEntries == ["news"])
    }

    @Test func onProgramChannelResultTunesStreamAndCommits() throws {
        let model = try makeModel()
        model.query = "news"
        model.search()
        model.onProgramChannelResult(model.results.programs[0])
        #expect(model.tuneTarget?.url == "http://x/News")
        #expect(model.historyEntries == ["news"])
    }

    @Test func focusHandlersUpdateSelectionAndDetailCard() throws {
        let model = try makeModel()
        model.query = "news"
        model.search()
        let channel = model.results.programs[0]
        model.onProgramChannelFocused(channel)
        #expect(model.selectedChannel?.channel.source.name == "News")
        #expect(model.focusedProgram?.title == "News Live")
        model.onProgramFocused(channel.airings[0])
        #expect(model.focusedProgram?.title == "News Live")
    }

    @Test func loadPopulatesHistoryFromStore() throws {
        let store = InMemoryKeyValueStore()
        SearchHistory(store: store).record("sports")
        let model = try makeModel(store: store)
        #expect(model.historyEntries.isEmpty)
        model.load()
        #expect(model.historyEntries == ["sports"])
    }
}
