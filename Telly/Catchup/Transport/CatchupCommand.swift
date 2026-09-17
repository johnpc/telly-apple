import Foundation

/// What a catch-up-aware key press should do. Ports the Android `CatchupCommand`
/// sealed interface (`CatchupKeyPolicy.kt:7-19`).
enum CatchupCommand: Equatable, Sendable {
    /// Relative seek within the finite archive stream, in milliseconds.
    case seek(deltaMs: Int)
    /// Jump into catch-up of the airing programme at live edge − `deltaMs`.
    case rewindLive(deltaMs: Int)
    /// BACK at bare catch-up playback: return to live / the guide.
    case back
}
