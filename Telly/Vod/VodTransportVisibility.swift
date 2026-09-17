import Foundation

/// The seek transport's auto-hide, as deadline math over an injected clock (the
/// ``OverlayVisibility`` idiom, applied to VOD — NOT Android's coroutine
/// `delay`). A `poke` reveals it; while playing it expires ``hideAfterMs`` after
/// the last poke, and while paused it stays up (no armed deadline). The screen's
/// per-second ticker calls `resolve(at:)`, so there is no wall clock here.
struct VodTransportVisibility {
    private(set) var visible = false
    private var deadlineMs: Int?

    static let hideAfterMs = 5_000

    /// Any interaction shows the transport; playing arms the auto-hide, paused
    /// cancels it so the row stays visible.
    mutating func poke(paused: Bool, at nowMs: Int) {
        visible = true
        deadlineMs = paused ? nil : nowMs + Self.hideAfterMs
    }

    /// Apply elapsed time: hide once an armed deadline passes, then report the
    /// visibility this frame.
    @discardableResult
    mutating func resolve(at nowMs: Int) -> Bool {
        if let deadline = deadlineMs, nowMs >= deadline {
            visible = false
            deadlineMs = nil
        }
        return visible
    }
}
