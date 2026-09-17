import Foundation

/// How catch-up relates to what is playing right now. Ports the Android
/// `CatchupMode` enum (`CatchupKeyPolicy.kt:22`).
enum CatchupMode: Equatable, Sendable {
    /// Not a catch-up channel: the key policy never acts.
    case none
    /// Live playback of a channel that offers catch-up (rewind-into-archive).
    case liveCapable
    /// Archive playback is under way (finite stream: seek/skip apply).
    case playing
}
