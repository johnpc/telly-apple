import Foundation

/// The catch-up playback position, in milliseconds. Clock-free by design: it is
/// only ever moved by an explicit `refresh` (sampled from the engine by the
/// screen's per-second UI ticker) or a `set` (on an explicit seek), so the logic
/// layer never spins its own clock loop. Ports the Android `CatchupPosition`.
@MainActor
struct CatchupPositionTracker {
    private(set) var position = 0

    /// Returns to the window start (a fresh archive entry).
    mutating func reset() { position = 0 }

    /// Samples the live position from the engine.
    mutating func refresh(from engine: any PlayerEngine) {
        position = engine.positionMs
    }

    /// Pins the position to an absolute value (used right after a seek).
    mutating func set(_ ms: Int) { position = ms }
}
