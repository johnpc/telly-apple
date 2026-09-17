import Foundation

/// One Movies-browser card: the VOD item plus its stored "Continue watching"
/// progress (`progressPermille`, nil when no resume position exists). Identity
/// is the item's refresh-stable `itemKey` so SwiftUI diffs survive refreshes.
/// Apple mirror of Android's `VodCard`.
struct VodCard: Identifiable, Equatable {
    let item: VodItem
    let progressPermille: Int?

    var id: String { item.itemKey }
}
