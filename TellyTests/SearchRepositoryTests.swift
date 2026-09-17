import Foundation
import Testing
import GRDB
@testable import Telly

/// `SearchRepository` orchestration (Android `SearchRepository`): normalize →
/// empty short-circuit → channel matches over the VISIBLE set (``ChannelSearch``)
/// with now/next attached → programme title matches grouped by channel. Hidden
/// channels drop from both channel hits AND programme-channel resolution; ended
/// airings drop at `atMs`. Fixed clock + UTC keep it deterministic.
struct SearchRepositoryTests {
    private static let atMs = 1_000
    private let utc = TimeZone(identifier: "UTC")!

    private func m(_ name: String, _ group: String = "Live") -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ tvgId: String, _ start: Int, _ end: Int, title: String) -> XmltvProgram {
        XmltvProgram(channelId: tvgId, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    private func makeRepo(channels: [M3uChannel], hidden: Set<String> = [],
                          programs: [XmltvProgram] = []) throws -> SearchRepository {
        let db = try AppDatabase.makeInMemory()
        _ = try PlaylistStore(db: db).add(sourceUrl: "u", playlist: M3uPlaylist(channels: channels),
                                          name: nil, nowMs: 0)
        for name in hidden {
            try db.queue.write { try $0.execute(sql: "UPDATE channels SET hidden = 1 WHERE name = ?",
                                                arguments: [name]) }
        }
        let programStore = ProgramStore(db: db)
        try programStore.upsertReplacing(document: XmltvDocument(channels: [], programs: programs),
                                         keepDescriptions: true)
        return SearchRepository(channelStore: ChannelStore(db: db), programStore: programStore,
                                epg: EpgRepository(store: programStore))
    }

    private func search(_ repo: SearchRepository, _ raw: String) throws -> SearchResults {
        try repo.search(raw, atMs: Self.atMs, timeZone: utc)
    }

    @Test func channelNameMatchAttachesNowProgramme() throws {
        let repo = try makeRepo(channels: [m("News"), m("Sports")],
                                programs: [prog("News", 900, 1_500, title: "News Live")])
        let results = try search(repo, "news")
        #expect(results.query == "news")
        #expect(results.channels.map { $0.channel.source.name } == ["News"])
        #expect(results.channels.first?.nowTitle == "News Live")
    }

    @Test func channelNumberMatchWorksForDigitQuery() throws {
        // Playlist order assigns numbers 1, 2 — an all-digit query hits by number.
        let repo = try makeRepo(channels: [m("Alpha"), m("Beta")])
        let results = try search(repo, "2")
        #expect(results.channels.map { $0.channel.source.name } == ["Beta"])
    }

    @Test func programmeTitleMatchReturnsGroupedShelf() throws {
        let repo = try makeRepo(channels: [m("Channel One")],
                                programs: [prog("Channel One", 900, 1_500, title: "Morning Report")])
        let results = try search(repo, "morning")
        #expect(results.channels.isEmpty) // "morning" matches no channel name/number
        #expect(results.programs.count == 1)
        #expect(results.programs.first?.channel.source.name == "Channel One")
        #expect(results.programs.first?.airings.map(\.title) == ["Morning Report"])
    }

    @Test func emptyAndWhitespaceQueryReturnsEmptyResults() throws {
        let repo = try makeRepo(channels: [m("News")],
                                programs: [prog("News", 900, 1_500, title: "News Live")])
        let blank = try search(repo, "   ")
        #expect(blank.isEmpty)
        #expect(blank.query.isEmpty)
        #expect(try search(repo, "").isEmpty)
    }

    @Test func hiddenChannelsExcludedFromChannelsAndProgrammeResolution() throws {
        // Hidden "News" (and its programme) must vanish from BOTH shelves; the
        // visible "Newsline" is the positive control.
        let repo = try makeRepo(
            channels: [m("News"), m("Newsline")],
            hidden: ["News"],
            programs: [prog("News", 900, 1_500, title: "News Live"),
                       prog("Newsline", 900, 1_500, title: "Newsline Report")])
        let results = try search(repo, "news")
        #expect(results.channels.map { $0.channel.source.name } == ["Newsline"])
        #expect(results.programs.map { $0.channel.source.name } == ["Newsline"])
        #expect(results.programs.flatMap { $0.airings.map(\.title) } == ["Newsline Report"])
    }

    @Test func endedAiringsFilteredOutByAtMs() throws {
        let repo = try makeRepo(
            channels: [m("Channel One")],
            programs: [prog("Channel One", 0, 500, title: "Ended Show"),
                       prog("Channel One", 900, 1_500, title: "Live Show")])
        let results = try search(repo, "show")
        #expect(results.programs.first?.airings.map(\.title) == ["Live Show"])
    }
}
