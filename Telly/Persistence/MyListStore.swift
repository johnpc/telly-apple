import GRDB

/// Read/write queries over the `my_list` table — the Apple mirror of the
/// Android `MyListDao`. No wall clock lives here: `save` takes the fully-formed
/// entry (its `addedAtMs` injected by the caller, the History/Vod convention).
/// The natural composite-PK upsert dedupes a re-saved airing, and `all` returns
/// newest-added first.
struct MyListStore {
    let db: AppDatabase

    /// Upserts a saved programme; the composite PK `(channelKey, startMs)`
    /// replaces a re-saved airing in place (so the toggle never dupes).
    func save(_ entry: MyListEntry) throws {
        try db.queue.write { try MyListRecord(entry).insert($0, onConflict: .replace) }
    }

    /// Removes the saved airing identified by `(channelKey, startMs)`.
    func remove(channelKey: String, startMs: Int) throws {
        try db.queue.write {
            _ = try MyListRecord
                .filter(Column("channelKey") == channelKey && Column("startMs") == Int64(startMs))
                .deleteAll($0)
        }
    }

    /// Every saved programme, newest-added first (the display order).
    func all() throws -> [MyListEntry] {
        try db.queue.read {
            try MyListRecord.fetchAll($0, sql: """
                SELECT * FROM my_list ORDER BY addedAtMs DESC, channelKey, startMs
                """).map(\.entity)
        }
    }
}
