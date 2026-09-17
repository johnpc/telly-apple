import Foundation

/// Where a transport ⏮/⏭ hop lands. Ports the Android `CatchupJump` sealed
/// interface (`CatchupNeighbours.kt:10-17`).
enum CatchupJump: Equatable {
    case archive(CatchupRequest)
    /// Past the newest archive (or off the EPG edge): back to live.
    case live
}
