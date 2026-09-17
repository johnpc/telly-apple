import Foundation

/// The small identity wrappers `ChannelListScreen` presents over, split out to
/// keep the screen file within the source-line budget (freeing room for the VOD
/// browser factory). `PlaybackTarget` drives the live-player fullscreen cover;
/// `ParentalChannelBox` boxes a channel awaiting a PIN sheet so `.sheet(item:)`
/// gets its `Identifiable` without making ``ChannelEntity`` itself identifiable.
struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}

struct ParentalChannelBox: Identifiable {
    let channel: ChannelEntity
    var id: Int { channel.id }
}
