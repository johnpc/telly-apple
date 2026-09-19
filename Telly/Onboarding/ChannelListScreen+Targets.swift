import Foundation

/// The identity wrapper `ChannelListScreen` presents over, split out to keep the
/// screen file within the source-line budget (freeing room for the VOD browser
/// factory). `PlaybackTarget` drives the live-player fullscreen cover.
struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}
