import GRDB

/// One user-added playlist. `url` is the identity a re-add replaces on;
/// `lastUpdatedMs` / `epgLastUpdatedMs` feed the refresh-scheduler policy
/// (0 means "never", i.e. always due). Flat, so it doubles as its own SQLite
/// row (the Android `PlaylistEntity` is likewise a bare Room `@Entity`).
struct PlaylistEntity: Codable, Equatable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "playlists"

    var id: Int64?
    var name: String
    var url: String
    var epgUrl: String?
    var lastUpdatedMs: Int64 = 0
    var epgLastUpdatedMs: Int64 = 0

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
