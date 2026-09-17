import GRDB

/// Flat SQLite row for one custom EPG source, keyed by the playlist's stable
/// URL (which survives re-imports) — the Apple mirror of the Android
/// `EpgSourceEntity`. A unique index on `(playlistUrl, url)` dedupes re-adds;
/// `addedAtMs` (an injected clock) fixes the fetch/merge order.
struct EpgSourceEntity: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "epg_sources"

    var id: Int64?
    var playlistUrl: String
    var url: String
    var addedAtMs: Int64

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
