import GRDB

/// Flat SQLite row for one saved My List programme. The natural composite
/// primary key `(channelKey, startMs)` means no autoincrement, so this is a
/// plain `PersistableRecord` (not `MutablePersistableRecord`/`didInsert`).
/// Conversions to and from the domain `MyListEntry` live alongside.
struct MyListRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "my_list"

    var channelKey: String
    var startMs: Int64
    var endMs: Int64
    var title: String
    var description: String?
    var addedAtMs: Int64
}
