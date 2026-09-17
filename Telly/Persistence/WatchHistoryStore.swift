import GRDB

/// Read/write queries over the `watch_history` table — the Apple mirror of the
/// Android `WatchHistoryDao`. No wall clock lives here: `record` takes the tune
/// timestamp so callers inject it (the composition root reads the clock). The
/// natural-PK upsert dedupes on re-watch, and each record trims to the newest
/// `cap` entries.
struct WatchHistoryStore {
    let db: AppDatabase

    /// Matches the Android `WatchHistory.CAP` — most recent channels retained.
    static let cap = 30

    /// Records a tune at `atMs`: upserts the entry (PK replace moves a re-watched
    /// channel to the top), then trims to the newest `cap` by `(watchedAtMs DESC,
    /// channelKey)`.
    func record(channelKey: String, atMs: Int) throws {
        try db.queue.write { db in
            try WatchHistoryRecord(WatchHistoryEntry(channelKey: channelKey, watchedAtMs: atMs))
                .insert(db, onConflict: .replace)
            try db.execute(sql: """
                DELETE FROM watch_history WHERE channelKey NOT IN (
                    SELECT channelKey FROM watch_history
                    ORDER BY watchedAtMs DESC, channelKey LIMIT ?)
                """, arguments: [Self.cap])
        }
    }

    /// The most recently watched entries, newest first, capped at `limit`.
    func recent(limit: Int = cap) throws -> [WatchHistoryEntry] {
        try db.queue.read {
            try WatchHistoryRecord.fetchAll($0, sql: """
                SELECT * FROM watch_history ORDER BY watchedAtMs DESC, channelKey LIMIT ?
                """, arguments: [limit]).map(\.entity)
        }
    }

    /// Empties the history (info-overlay Clear card + History screen trash).
    func clear() throws {
        try db.queue.write { _ = try WatchHistoryRecord.deleteAll($0) }
    }
}
