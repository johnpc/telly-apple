#if DEBUG
import Foundation

/// DEBUG-only launch flag seeding the recently-watched screen for the screenshot
/// proof (`-tellyHistorySeed`), never touching the real provider. Kept in its own
/// file so the 99-line `DebugLaunch` core stays untouched.
extension DebugLaunch {
    /// Whether to route straight to the History screen with three seeded fixture
    /// channels — set by `-tellyHistorySeed`.
    static func historyDemoRequested(in args: [String]) -> Bool {
        args.contains("-tellyHistorySeed")
    }

    /// Records the first three visible fixture channels into `store`, descending
    /// by timestamp (newest first): first @ `now`, second @ `now - 60_000`, third
    /// @ `now - 120_000`, each keyed by ``ChannelImporter/keyOf``. Idempotent (the
    /// store upserts on the natural key); a no-op without the flag.
    static func seedHistoryIfRequested(into store: WatchHistoryStore,
                                       channels: [ChannelEntity],
                                       args: [String], now: Int) {
        guard historyDemoRequested(in: args) else { return }
        for (offset, channel) in channels.prefix(3).enumerated() {
            try? store.record(channelKey: ChannelImporter.keyOf(channel),
                              atMs: now - offset * 60_000)
        }
    }
}
#endif
