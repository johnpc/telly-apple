import Foundation

/// Coalesces rapid channel-up/down presses into a single tune. Each press
/// accumulates its delta and re-arms a settle deadline; once presses stop for
/// `settleMs`, `resolve` yields the net delta once for ONE ChannelZapper step.
/// Pure and clock-injected (nowMs), mirroring `OverlayVisibility`.
///
/// APPLE-PORT ADDITION, not a port: Android tunes on every press
/// (TuneController.kt:125-129). VLCKit rebuilds its pipeline per media swap, so
/// a fast CH+ hold must not tune N times. `settleMs` has no Android origin —
/// 250 ms is a starting value to tune on-device.
struct PendingZap: Equatable {
    private(set) var accumulatedDelta = 0
    private var deadlineMs: Int?
    private let settleMs: Int

    init(settleMs: Int = 250) { self.settleMs = settleMs }

    mutating func press(delta: Int, at nowMs: Int) {
        accumulatedDelta += delta
        deadlineMs = nowMs + settleMs
    }

    /// Once presses have settled, return coalesced net delta ONCE and clear;
    /// nil while still within the window or when nothing pends.
    mutating func resolve(at nowMs: Int) -> Int? {
        guard let deadline = deadlineMs, nowMs >= deadline else { return nil }
        defer { accumulatedDelta = 0; deadlineMs = nil }
        return accumulatedDelta
    }
}
