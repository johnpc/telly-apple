import Foundation

/// Pure shaping for the Movies browser (Apple mirror of Android's `VodBrowse`):
/// categories are the items' preserved group-titles in playlist order
/// (blank/missing group -> ``uncategorized``), and cards are the selected
/// category's items joined with their stored resume positions -> `progressPermille`.
enum VodBrowse {
    static let uncategorized = "Uncategorized"
    private static let permille = 1000

    /// Distinct category labels in playlist/sort order.
    static func categories(_ items: [VodItem]) -> [String] {
        var seen = Set<String>()
        return items.map(categoryOf).filter { seen.insert($0).inserted }
    }

    /// The selected category's items joined to stored positions. A nil
    /// `category` keeps every item; each card's permille comes from a matching
    /// position (nil when absent or duration <= 0).
    static func cards(items: [VodItem], positions: [VodPosition], category: String?) -> [VodCard] {
        let byKey = Dictionary(positions.map { ($0.itemKey, $0) }, uniquingKeysWith: { first, _ in first })
        return items
            .filter { category == nil || categoryOf($0) == category }
            .map { VodCard(item: $0, progressPermille: byKey[$0.itemKey].flatMap(permilleOf)) }
    }

    /// The item's browser category: its group-title, or ``uncategorized`` when blank.
    static func categoryOf(_ item: VodItem) -> String {
        let group = item.groupTitle?.trimmingCharacters(in: .whitespaces) ?? ""
        return group.isEmpty ? uncategorized : (item.groupTitle ?? uncategorized)
    }

    private static func permilleOf(_ position: VodPosition) -> Int? {
        guard position.durationMs > 0 else { return nil }
        return min(max(position.positionMs * permille / position.durationMs, 0), permille)
    }
}
