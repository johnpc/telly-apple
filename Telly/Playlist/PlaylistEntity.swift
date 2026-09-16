import Foundation

/// One user-added playlist. `url` is the identity a re-add replaces on;
/// `lastUpdatedMs` / `epgLastUpdatedMs` feed the refresh policy (0 means
/// "never", i.e. always due).
struct PlaylistEntity: Equatable {
    var id: Int = 0
    let name: String
    let url: String
    var epgUrl: String?
    var lastUpdatedMs: Int = 0
    var epgLastUpdatedMs: Int = 0
}

/// A per-channel EPG time offset projection consumed by `EpgOffsets`.
struct TvgOffset: Equatable {
    let tvgId: String?
    let epgOffsetMinutes: Int
}
