import Foundation

/// A per-channel EPG time offset projection consumed by `EpgOffsets`: the
/// channel's tvg-id and its "EPG time offset" (Channel options) in minutes.
struct TvgOffset: Equatable {
    let tvgId: String?
    let epgOffsetMinutes: Int
}
