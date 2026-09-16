import Foundation

/// Live-stream auto-reconnect budget. On each player error the engine asks for
/// the ``nextDelayMs()`` backoff — 1s, 2s, 4s, 8s… doubling and capped at
/// `maxDelayMs` — and re-prepares the current media item after it. Once
/// `maxAttempts` retries are spent ``nextDelayMs()`` returns `nil` and the
/// engine surfaces a hard error. A successful (re)connect calls ``reset()``, so
/// a stream that drops again hours later gets a fresh budget. Pure logic, no
/// clock or platform types — the engine owns the actual scheduling so this
/// stays unit-testable (ported from the Android `ReconnectPolicy`).
struct ReconnectPolicy {
    private let maxAttempts: Int
    private let baseDelayMs: Int
    private let maxDelayMs: Int
    private var attempt = 0

    init(maxAttempts: Int = 6, baseDelayMs: Int = 1_000, maxDelayMs: Int = 30_000) {
        self.maxAttempts = maxAttempts
        self.baseDelayMs = baseDelayMs
        self.maxDelayMs = maxDelayMs
    }

    /// Next backoff delay in milliseconds, or `nil` once the retry budget is spent.
    mutating func nextDelayMs() -> Int? {
        guard attempt < maxAttempts else { return nil }
        let delay = min(baseDelayMs << attempt, maxDelayMs)
        attempt += 1
        return delay
    }

    /// Clears the spent attempts after a successful (re)connect.
    mutating func reset() {
        attempt = 0
    }
}
