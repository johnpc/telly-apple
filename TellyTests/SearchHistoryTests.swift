import Testing
@testable import Telly

/// The persisted recent-query list: normalize-on-record, case-insensitive
/// move-to-front dedupe, the 20-entry cap, clear, and the save-history gate —
/// all over the in-memory ``KeyValueStore`` fake.
struct SearchHistoryTests {
    private func history(save: @escaping () -> Bool = { true }) -> SearchHistory {
        SearchHistory(store: InMemoryKeyValueStore(), saveEnabled: save)
    }

    @Test func recordThenListReturnsNormalizedQuery() {
        let h = history()
        h.record("  news   sports  ")
        #expect(h.list() == ["news sports"])   // trimmed + internal runs collapsed
    }

    @Test func reSearchMovesToFront() {
        let h = history()
        h.record("a")
        h.record("b")
        h.record("a")
        #expect(h.list() == ["a", "b"])
    }

    @Test func dedupeIsCaseInsensitiveNewestCasingWins() {
        let h = history()
        h.record("News")
        h.record("news")
        #expect(h.list() == ["news"])   // most-recent casing at the front, single entry
    }

    @Test func capsAtTwentyEntriesNewestFirst() {
        let h = history()
        for i in 1 ... 25 { h.record("q\(i)") }
        let list = h.list()
        #expect(list.count == 20)
        #expect(list.first == "q25")
        #expect(list.last == "q6")
    }

    @Test func clearEmptiesTheHistory() {
        let h = history()
        h.record("a")
        h.clear()
        #expect(h.list() == [])
    }

    @Test func recordIsNoOpWhenSaveDisabled() {
        let h = history(save: { false })
        h.record("a")
        #expect(h.list() == [])
    }

    @Test func blankInputIsIgnored() {
        let h = history()
        h.record("   ")
        h.record("")
        #expect(h.list() == [])
    }

    @Test func defaultSaveEnabledRecords() {
        let h = SearchHistory(store: InMemoryKeyValueStore())
        h.record("x")
        #expect(h.list() == ["x"])
    }
}
