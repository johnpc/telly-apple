import Foundation

/// One tile in the multiview grid: a stable identity (the channel id) plus the
/// channel it shows and the stream URL to load. A value type so the grid's
/// immutable transforms rebuild the cell list without ever touching an engine.
struct MultiviewCell: Equatable, Identifiable {
    let id: Int
    let channel: ChannelEntity
    var streamUrl: String

    init(channel: ChannelEntity) {
        self.id = channel.id
        self.channel = channel
        self.streamUrl = channel.source.streamUrl
    }
}
