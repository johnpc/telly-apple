import GRDB

/// Flat SQLite row for one watch-history entry. A natural string primary key
/// (`channelKey`) means no autoincrement, so this is a plain `PersistableRecord`
/// (not `MutablePersistableRecord`/`didInsert`). Conversions to and from the
/// domain `WatchHistoryEntry` live alongside.
struct WatchHistoryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "watch_history"

    var channelKey: String
    var watchedAtMs: Int64
}
