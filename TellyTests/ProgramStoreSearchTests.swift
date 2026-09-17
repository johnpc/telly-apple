import Testing
import GRDB
@testable import Telly

/// `ProgramStore.searchTitles` — the word-prefix title query (Android
/// `SearchDao.programs`): `' ' || title` LIKE the escaped pattern, still
/// airing at `atMs`, soonest first, capped by `limit`.
struct ProgramStoreSearchTests {
    private static let atMs = 1_000

    private func makeStore() throws -> ProgramStore {
        ProgramStore(db: try AppDatabase.makeInMemory())
    }

    private func prog(_ channel: String, _ start: Int, _ end: Int, title: String) -> XmltvProgram {
        XmltvProgram(channelId: channel, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    private func seed(_ store: ProgramStore, _ programs: [XmltvProgram]) throws {
        try store.upsertReplacing(document: XmltvDocument(channels: [], programs: programs),
                                  keepDescriptions: true)
    }

    private func search(_ store: ProgramStore, _ query: String, limit: Int = 100) throws -> [ProgramEntity] {
        try store.searchTitles(titleLike: SearchQuery.nameLike(query), atMs: Self.atMs, limit: limit)
    }

    @Test func wordPrefixMatchesMidTitleWord() throws {
        let store = try makeStore()
        try seed(store, [prog("a", 1_100, 1_500, title: "Late Special")])
        #expect(try search(store, "spec").map(\.details.title) == ["Late Special"])
    }

    @Test func doesNotMatchMidWord() throws {
        let store = try makeStore()
        try seed(store, [prog("b", 1_100, 1_500, title: "Newsroom")])
        #expect(try search(store, "room").isEmpty)
    }

    @Test func excludesAlreadyEndedProgrammes() throws {
        let store = try makeStore()
        try seed(store, [prog("a", 0, 500, title: "News Ended"),
                         prog("b", 900, 1_500, title: "News Live")])
        #expect(try search(store, "news").map(\.details.title) == ["News Live"])
    }

    @Test func ordersByStartThenChannel() throws {
        let store = try makeStore()
        try seed(store, [prog("b", 1_200, 1_600, title: "Show"),
                         prog("a", 1_200, 1_600, title: "Show"),
                         prog("a", 1_100, 1_600, title: "Show")])
        let rows = try search(store, "show")
        #expect(rows.map { [$0.startMs, $0.channelTvgId] as [AnyHashable] }
            == [[1_100, "a"], [1_200, "a"], [1_200, "b"]])
    }

    @Test func limitCapsToTheSoonestMatches() throws {
        let store = try makeStore()
        try seed(store, (0..<5).map { prog("x", 1_100 + $0 * 100, 2_000, title: "Match Show") })
        let rows = try search(store, "match", limit: 3)
        #expect(rows.map(\.startMs) == [1_100, 1_200, 1_300])
    }

    @Test func escapedPercentMatchesLiterallyOnly() throws {
        let store = try makeStore()
        try seed(store, [prog("a", 1_100, 1_500, title: "50% Off Show"),
                         prog("b", 1_100, 1_500, title: "5000 Show")])
        #expect(try search(store, "50%").map(\.details.title) == ["50% Off Show"])
    }
}
