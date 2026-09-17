import Foundation

extension VodItemRecord {
    /// Builds a persistence row from a domain item (`Int` => `Int64` at the row
    /// boundary, as `ChannelRecord` does).
    init(_ i: VodItem) {
        self.init(id: i.id.map(Int64.init), playlistId: Int64(i.playlistId), sortIndex: i.sortIndex,
                  itemKey: i.itemKey, name: i.name, groupTitle: i.groupTitle,
                  logoUrl: i.logoUrl, streamUrl: i.streamUrl)
    }

    /// The domain item this row represents (narrows `Int64` => `Int`).
    var entity: VodItem {
        VodItem(id: id.map(Int.init), playlistId: Int(playlistId), sortIndex: sortIndex,
                itemKey: itemKey, name: name, groupTitle: groupTitle,
                logoUrl: logoUrl, streamUrl: streamUrl)
    }
}

/// One VOD movie: its playlist/order, refresh-stable resume `itemKey`, display
/// name, browser `groupTitle`, card `logoUrl`, and stream URL.
struct VodItem: Equatable {
    var id: Int?
    let playlistId: Int
    let sortIndex: Int
    let itemKey: String
    let name: String
    let groupTitle: String?
    let logoUrl: String?
    let streamUrl: String
}
