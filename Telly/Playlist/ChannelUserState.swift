import Foundation

/// Per-channel user state that must survive playlist refreshes (carried over
/// by `ChannelImporter` keyed on channel identity).
struct ChannelFlags: Equatable {
    var favorite = false
    var hidden = false
    /// Manage-Favorites position; ties keep the base zap order.
    var favoriteOrder = 0
    /// PIN-gated to tune: blocked channels stay listed with a lock.
    var blocked = false
}

/// Per-channel "Channel options" overrides: all default to "follow the
/// playlist/global" and survive playlist refreshes like `ChannelFlags`.
struct ChannelOverrides: Equatable {
    /// Custom display name; nil/blank = the playlist name.
    var customName: String?
    /// "Hardware"/"Software"; nil = the global Playback setting.
    var audioDecoder: String?
    var videoDecoder: String?
    /// Shifts this channel's EPG programme times for display.
    var epgOffsetMinutes = 0
    /// "On"/"Off"; nil = the global "Use external player" setting.
    var externalPlayer: String?
    /// Per-channel EPG id override (Assign EPG); nil = auto (tvg-id).
    var epgOverride: String?
}
