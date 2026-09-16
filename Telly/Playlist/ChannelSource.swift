import Foundation

/// Where a channel comes from and how it is labelled in the playlist.
/// Re-imported from the M3U on every refresh.
struct ChannelSource: Equatable {
    let name: String
    var groupTitle: String?
    var logoUrl: String?
    let streamUrl: String
    var tvgId: String?
}

/// Catch-up capability as declared on the channel's `#EXTINF` line
/// (`catchup` / `catchup-source` / `catchup-days`); re-imported on every
/// refresh like the rest of `ChannelSource`.
struct ChannelCatchup: Equatable {
    var catchupType: String?
    var catchupSource: String?
    var catchupDays: Int?
}
