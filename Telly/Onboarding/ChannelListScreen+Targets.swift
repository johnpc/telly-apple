import Foundation

/// The identity wrapper `ChannelListScreen` presents over, split out to keep the
/// screen file within the source-line budget (freeing room for the VOD browser
/// factory). `PlaybackTarget` drives the live-player fullscreen cover.
struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}

/// The identity wrapper the row menu's "Assign EPG" action presents its sheet
/// over — the per-channel ``AssignEpgScreen`` target (mirrors ``PlaybackTarget``).
struct AssignEpgTarget: Identifiable {
    let channel: ChannelEntity
    var id: Int { channel.id }
}
