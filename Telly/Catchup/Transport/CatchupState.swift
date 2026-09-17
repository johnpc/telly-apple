import Foundation

/// The active archive session: the request being played and whether it was
/// entered by rewinding from live (so BACK returns to live rather than the
/// guide). Ports the Android `CatchupPlayback` state (`CatchupPlayback.kt:13-16`).
struct CatchupState: Equatable {
    let request: CatchupRequest
    let fromLive: Bool
}
