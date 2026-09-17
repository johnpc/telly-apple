import Testing
import GRDB
@testable import Telly

/// The Movies-browser model over REAL in-memory stores: `load` populates the
/// categories and cards from the seeded items+positions, defaults the selection
/// to the first category, `select` swaps the visible cards, and `isEmpty`
/// reflects an empty catalogue.
@MainActor
struct VodBrowseModelTests {
    private func item(_ name: String, _ group: String, _ index: Int) -> VodItem {
        VodItem(id: nil, playlistId: 1, sortIndex: index, itemKey: "\(name)|k",
                name: name, groupTitle: group, logoUrl: nil, streamUrl: "http://s/\(name).mp4")
    }

    private func model(items: [VodItem], positions: [VodPosition] = []) throws -> VodBrowseModel {
        let db = try AppDatabase.makeInMemory()
        let itemStore = VodItemStore(db: db)
        try itemStore.replace(playlistId: 1, items: items)
        let positionStore = VodPositionStore(db: db, remember: { true }, clock: { 1 })
        for position in positions {
            try positionStore.save(itemKey: position.itemKey, positionMs: position.positionMs,
                                   durationMs: position.durationMs)
        }
        return VodBrowseModel(itemStore: itemStore, positionStore: positionStore)
    }

    @Test func loadPopulatesCategoriesAndDefaultsToFirst() throws {
        let m = try model(items: [item("A", "Cinema", 0), item("B", "Docs", 1), item("C", "Cinema", 2)])
        m.load()
        #expect(m.categories == ["Cinema", "Docs"])
        #expect(m.selected == "Cinema")
        #expect(m.cards.map(\.item.name) == ["A", "C"])
        #expect(!m.isEmpty)
    }

    @Test func loadJoinsStoredProgress() throws {
        let a = item("A", "Cinema", 0)
        let position = VodPosition(itemKey: a.itemKey, positionMs: 15_000, durationMs: 60_000, updatedAtMs: 1)
        let m = try model(items: [a], positions: [position])
        m.load()
        #expect(m.cards.first?.progressPermille == 250)
    }

    @Test func selectSwapsVisibleCards() throws {
        let m = try model(items: [item("A", "Cinema", 0), item("B", "Docs", 1)])
        m.load()
        m.select("Docs")
        #expect(m.selected == "Docs")
        #expect(m.cards.map(\.item.name) == ["B"])
    }

    @Test func isEmptyWhenNoItems() throws {
        let m = try model(items: [])
        m.load()
        #expect(m.isEmpty)
        #expect(m.categories.isEmpty)
        #expect(m.cards.isEmpty)
        #expect(m.selected == nil)
    }
}
