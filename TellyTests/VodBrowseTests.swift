import Testing
@testable import Telly

/// Pure Movies-browser shaping: distinct categories in playlist order, blank
/// groups fold into "Uncategorized", the selected category filters the cards,
/// and stored positions join to a clamped permille (nil when absent or dur<=0).
struct VodBrowseTests {
    private func item(_ name: String, _ group: String?, _ index: Int = 0) -> VodItem {
        VodItem(id: nil, playlistId: 1, sortIndex: index, itemKey: "http://s/\(name).mp4|\(name)",
                name: name, groupTitle: group, logoUrl: nil, streamUrl: "http://s/\(name).mp4")
    }

    @Test func categoriesAreDistinctInPlaylistOrder() {
        let items = [item("A", "Cinema", 0), item("B", "Docs", 1), item("C", "Cinema", 2),
                     item("D", "", 3), item("E", nil, 4)]
        #expect(VodBrowse.categories(items) == ["Cinema", "Docs", VodBrowse.uncategorized])
    }

    @Test func blankGroupBecomesUncategorized() {
        #expect(VodBrowse.categoryOf(item("A", "   ")) == VodBrowse.uncategorized)
        #expect(VodBrowse.categoryOf(item("A", nil)) == VodBrowse.uncategorized)
        #expect(VodBrowse.categoryOf(item("A", "Cinema")) == "Cinema")
    }

    @Test func cardsFilterToCategoryAndJoinProgress() {
        let items = [item("A", "Cinema"), item("B", "Docs"), item("C", "Cinema")]
        let positions = [VodPosition(itemKey: items[0].itemKey, positionMs: 15_000, durationMs: 60_000, updatedAtMs: 1)]
        let cards = VodBrowse.cards(items: items, positions: positions, category: "Cinema")
        #expect(cards.map(\.item.name) == ["A", "C"])
        #expect(cards.first?.progressPermille == 250)
        #expect(cards.last?.progressPermille == nil)
    }

    @Test func nilCategoryKeepsEveryItem() {
        let items = [item("A", "Cinema"), item("B", nil)]
        #expect(VodBrowse.cards(items: items, positions: [], category: nil).count == 2)
    }

    @Test func unknownDurationProducesNoProgress() {
        let items = [item("A", "Cinema")]
        let positions = [VodPosition(itemKey: items[0].itemKey, positionMs: 15_000, durationMs: 0, updatedAtMs: 1)]
        #expect(VodBrowse.cards(items: items, positions: positions, category: "Cinema").first?.progressPermille == nil)
    }

    @Test func progressClampsToPermilleRange() {
        let items = [item("A", "Cinema")]
        let positions = [VodPosition(itemKey: items[0].itemKey, positionMs: 90_000, durationMs: 60_000, updatedAtMs: 1)]
        #expect(VodBrowse.cards(items: items, positions: positions, category: "Cinema").first?.progressPermille == 1000)
    }

    @Test func cardIdentityIsItemKey() {
        let card = VodCard(item: item("A", "Cinema"), progressPermille: nil)
        #expect(card.id == "http://s/A.mp4|A")
    }
}
