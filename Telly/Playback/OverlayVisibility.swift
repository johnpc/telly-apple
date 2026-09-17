import Foundation

/// Holds the visible overlay and the auto-hide deadline of the transient ones
/// (info / transport / zap / quick-bar). Pure and clock-injected: every call is
/// given `nowMs`, so there is no scheduler or wall clock here — the S6
/// orchestrator drives `resolve(at:)` from its own clock. Ported from Android
/// `OverlayState`; the coroutine `delay`/`compareAndSet` become deadline math.
struct OverlayVisibility {
    private(set) var overlay: PlaybackOverlay = .none
    private var deadlineMs: Int?
    private var activeTimeoutMs = 0

    /// Sticky overlay (panel, menus, pinned transport); cancels any auto-hide.
    mutating func set(_ next: PlaybackOverlay) {
        overlay = next
        deadlineMs = nil
    }

    /// Show `next` and arm its auto-hide `timeoutMs` after `nowMs`.
    mutating func showAutoHiding(_ next: PlaybackOverlay, timeoutMs: Int, at nowMs: Int) {
        overlay = next
        activeTimeoutMs = timeoutMs
        deadlineMs = nowMs + timeoutMs
    }

    /// D-pad browsing keeps a transient overlay up: restart the countdown, but
    /// only while one is armed (keepAlive's isActive guard).
    mutating func keepAlive(at nowMs: Int) {
        guard deadlineMs != nil else { return }
        deadlineMs = nowMs + activeTimeoutMs
    }

    /// Apply elapsed time: expire to `.none` once the deadline passes, then
    /// return the overlay now visible.
    @discardableResult
    mutating func resolve(at nowMs: Int) -> PlaybackOverlay {
        if let deadline = deadlineMs, nowMs >= deadline {
            overlay = .none
            deadlineMs = nil
        }
        return overlay
    }
}
