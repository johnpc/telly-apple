import Testing
import GRDB
@testable import Telly

/// Raw GRDB behaviour of `ProgramStore`: replace-on-import, window/now-next
/// boundary predicates, the past trim, and distinct sorted channel ids.
struct ProgramStoreTests {
    private func makeStore() throws -> ProgramStore {
        ProgramStore(db: try AppDatabase.makeInMemory())
    }

    private func prog(_ channel: String, _ start: Int, _ end: Int,
                      title: String = "T", desc: String? = "D") -> XmltvProgram {
        XmltvProgram(channelId: channel, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: desc,
                                             category: nil, episode: nil))
    }

    private func seed(_ store: ProgramStore, _ programs: [XmltvProgram],
                      keepDescriptions: Bool = true) throws {
        try store.upsertReplacing(document: XmltvDocument(channels: [], programs: programs),
                                  keepDescriptions: keepDescriptions)
    }

    @Test func upsertReplaceDropsStaleRowsButKeepsOtherChannels() throws {
        let store = try makeStore()
        try seed(store, [prog("a", 0, 10), prog("a", 10, 20), prog("b", 0, 10)])
        try seed(store, [prog("a", 5, 15, title: "Fresh")])
        let a = try store.window(tvgIds: ["a"], fromMs: 0, toMs: 100)
        #expect(a.map(\.startMs) == [5])
        #expect(a.first?.details.title == "Fresh")
        #expect(try store.window(tvgIds: ["b"], fromMs: 0, toMs: 100).count == 1)
    }

    @Test func windowAppliesEndAfterFromAndStartBeforeTo() throws {
        let store = try makeStore()
        try seed(store, [prog("x", 0, 100), prog("x", 100, 200), prog("x", 200, 300)])
        let rows = try store.window(tvgIds: ["x"], fromMs: 100, toMs: 200)
        #expect(rows.map(\.startMs) == [100])
    }

    @Test func airingOrUpcomingExcludesEndedProgrammes() throws {
        let store = try makeStore()
        try seed(store, [prog("x", 0, 100), prog("x", 100, 200)])
        let rows = try store.airingOrUpcoming(tvgIds: ["x"], atMs: 150)
        #expect(rows.map(\.startMs) == [100])
    }

    @Test func emptyChannelListReturnsNoRows() throws {
        let store = try makeStore()
        try seed(store, [prog("x", 0, 100)])
        #expect(try store.window(tvgIds: [], fromMs: 0, toMs: 100).isEmpty)
        #expect(try store.airingOrUpcoming(tvgIds: [], atMs: 0).isEmpty)
    }

    @Test func trimEndedBeforeDeletesOnlyEndedProgrammes() throws {
        let store = try makeStore()
        try seed(store, [prog("x", 0, 100), prog("x", 100, 200)])
        try store.trimEndedBefore(cutoffMs: 150)
        let rows = try store.window(tvgIds: ["x"], fromMs: 0, toMs: 1_000)
        #expect(rows.map(\.startMs) == [100])
    }

    @Test func channelIdsAreDistinctAndSorted() throws {
        let store = try makeStore()
        try seed(store, [prog("c", 0, 10), prog("a", 0, 10), prog("a", 10, 20), prog("b", 0, 10)])
        #expect(try store.channelIds() == ["a", "b", "c"])
    }

    @Test func keepDescriptionsFalseNullsDescriptions() throws {
        let store = try makeStore()
        try seed(store, [prog("x", 0, 100, desc: "Synopsis")], keepDescriptions: false)
        let rows = try store.window(tvgIds: ["x"], fromMs: 0, toMs: 100)
        #expect(rows.first?.details.description == nil)
    }
}
