import GRDB

/// The `watch_history` table — recently-watched channels, mirroring the Android
/// Room `WatchHistoryEntity`. Keyed by the playlist-refresh-STABLE `channelKey`
/// (`ChannelImporter.keyOf`), NOT a channel row id: `PlaylistStore.add()`
/// reassigns row ids every refresh, so an FK would wipe history. Two columns
/// only — no position, no cascade. The natural string PK dedupes on re-watch;
/// the `watchedAtMs` index backs the newest-first ordering and trim.
enum HistorySchema {
    static func createWatchHistory(_ db: Database) throws {
        try db.create(table: "watch_history") { t in
            t.column("channelKey", .text).notNull().primaryKey()
            t.column("watchedAtMs", .integer).notNull()
        }
        try db.create(index: "index_watch_history_watchedAtMs", on: "watch_history",
                      columns: ["watchedAtMs"])
    }
}
