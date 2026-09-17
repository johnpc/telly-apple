#if DEBUG
import Foundation

/// DEBUG-only launch flag seeding the My List screen for the screenshot proof
/// (`-tellyMyListSeed`), never touching the real provider. Kept in its own file
/// so the 99-line `DebugLaunch` core stays untouched (the `+History` precedent).
extension DebugLaunch {
    /// Whether to route straight to the My List screen with two seeded fixture
    /// entries — set by `-tellyMyListSeed`.
    static func myListSeedRequested(in args: [String]) -> Bool {
        args.contains("-tellyMyListSeed")
    }

    /// Saves two fixture programmes into `store`: the first visible channel with
    /// an airing-NOW programme (`start ≤ now < end` → accent-tinted row) and the
    /// second with a FUTURE programme (`start > now` → description-tap row), each
    /// keyed by ``ChannelImporter/keyOf`` and snapshotted via ``MyListToggle``.
    /// Idempotent (composite-PK replace); a no-op without the flag.
    static func seedMyListIfRequested(into store: MyListStore, channels: [ChannelEntity],
                                      args: [String], now: Int) {
        guard myListSeedRequested(in: args), let first = channels.first else { return }
        let hour = 60 * 60_000
        try? store.save(MyListToggle.entry(
            channelKey: ChannelImporter.keyOf(first), title: "Evening News",
            description: "The day's headlines.", startMs: now - hour / 2,
            endMs: now + hour / 2, addedAtMs: now))
        guard channels.count > 1 else { return }
        try? store.save(MyListToggle.entry(
            channelKey: ChannelImporter.keyOf(channels[1]), title: "Late Documentary",
            description: "A deep dive, later tonight.", startMs: now + hour,
            endMs: now + 2 * hour, addedAtMs: now - 60_000))
    }
}
#endif
