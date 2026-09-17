import Testing
import GRDB
@testable import Telly

/// Raw GRDB behaviour of `MyListStore` against an in-memory `AppDatabase` (the
/// real backend): save→all round-trip, composite-PK replace-dedupe, newest-added
/// ordering, and remove. Ports the Android `MyListDaoTest` cases.
struct MyListStoreTests {
    private func makeStore() throws -> MyListStore {
        MyListStore(db: try AppDatabase.makeInMemory())
    }

    private func entry(_ key: String, start: Int, added: Int, title: String = "T") -> MyListEntry {
        MyListEntry(channelKey: key, startMs: start, endMs: start + 3_600_000,
                    title: title, description: nil, addedAtMs: added)
    }

    @Test func savesAndReadsBackRoundTrip() throws {
        let store = try makeStore()
        let e = MyListEntry(channelKey: "a", startMs: 100, endMs: 200,
                            title: "Show", description: "Desc", addedAtMs: 500)
        try store.save(e)
        #expect(try store.all() == [e])
    }

    @Test func reSavingSameAiringReplacesInPlace() throws {
        let store = try makeStore()
        try store.save(entry("a", start: 100, added: 1, title: "Old"))
        try store.save(entry("a", start: 100, added: 9, title: "New"))
        let all = try store.all()
        #expect(all.count == 1)
        #expect(all.first?.title == "New")
        #expect(all.first?.addedAtMs == 9)
    }

    @Test func allIsNewestAddedFirst() throws {
        let store = try makeStore()
        try store.save(entry("a", start: 1, added: 100))
        try store.save(entry("b", start: 2, added: 300))
        try store.save(entry("c", start: 3, added: 200))
        #expect(try store.all().map(\.channelKey) == ["b", "c", "a"])
    }

    @Test func removeDeletesByCompositeKey() throws {
        let store = try makeStore()
        try store.save(entry("a", start: 100, added: 1))
        try store.save(entry("a", start: 200, added: 2))
        try store.remove(channelKey: "a", startMs: 100)
        #expect(try store.all().map(\.startMs) == [200])
    }
}
