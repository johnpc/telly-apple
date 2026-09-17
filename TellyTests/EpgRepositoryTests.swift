import Testing
import GRDB
@testable import Telly

/// `EpgRepository` applies per-channel offsets around the raw store: the query
/// bound is padded so rows that shift into view survive, and returned times are
/// shifted into display time. Zero offsets pass through unchanged.
struct EpgRepositoryTests {
    private func makeRepo(_ programs: [XmltvProgram]) throws -> EpgRepository {
        let store = ProgramStore(db: try AppDatabase.makeInMemory())
        try store.upsertReplacing(document: XmltvDocument(channels: [], programs: programs),
                                  keepDescriptions: true)
        return EpgRepository(store: store)
    }

    private func prog(_ channel: String, _ start: Int, _ end: Int) -> XmltvProgram {
        XmltvProgram(channelId: channel, startMs: start, endMs: end,
                     details: ProgramDetails(title: "T", subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    @Test func programsPadQueryBoundAndShiftResults() throws {
        // Stored [-80,-40] sits entirely before the [0,100) window, but a +50
        // offset shifts it to [-30,10] which overlaps — only the padded query
        // catches it, and the returned times are the shifted ones.
        let repo = try makeRepo([prog("x", -80, -40)])
        #expect(try repo.store.window(tvgIds: ["x"], fromMs: 0, toMs: 100).isEmpty)
        let rows = try repo.programs(tvgIds: ["x"], fromMs: 0, toMs: 100, offsets: ["x": 50])
        #expect(rows.count == 1)
        #expect(rows[0].startMs == -30)
        #expect(rows[0].endMs == 10)
    }

    @Test func programsZeroOffsetPassesThrough() throws {
        let repo = try makeRepo([prog("x", 10, 50)])
        let rows = try repo.programs(tvgIds: ["x"], fromMs: 0, toMs: 100, offsets: [:])
        #expect(rows.map { [$0.startMs, $0.endMs] } == [[10, 50]])
    }

    @Test func nowNextSelectsAiringThenUpcomingAndOmitsEmptyChannel() throws {
        let repo = try makeRepo([prog("x", 0, 100), prog("x", 100, 200), prog("x", 200, 300)])
        let result = try repo.nowNext(tvgIds: ["x", "y"], atMs: 50, offsets: [:])
        #expect(result.count == 1)
        #expect(result["y"] == nil)
        #expect(result["x"]?.now?.startMs == 0)
        #expect(result["x"]?.next?.startMs == 100)
    }

    @Test func nowNextAppliesOffsetToSelection() throws {
        // +20 offset shifts [0,100]->[20,120] (airing at 50) and
        // [100,200]->[120,220] (next); the padded query keeps both.
        let repo = try makeRepo([prog("x", 0, 100), prog("x", 100, 200)])
        let result = try repo.nowNext(tvgIds: ["x"], atMs: 50, offsets: ["x": 20])
        #expect(result["x"]?.now?.startMs == 20)
        #expect(result["x"]?.now?.endMs == 120)
        #expect(result["x"]?.next?.startMs == 120)
    }
}
