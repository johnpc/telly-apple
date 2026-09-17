import GRDB

/// Flat SQLite row for one VOD movie — the Apple mirror of the Android
/// `VodItemEntity`. `sortIndex` fixes playlist order; `id` is filled on insert
/// (autoincrement) via `didInsert`. Conversions to/from the domain `VodItem`
/// live alongside in `VodItemRecord+Entity`.
struct VodItemRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "vod_items"

    var id: Int64?
    var playlistId: Int64
    var sortIndex: Int
    var itemKey: String
    var name: String
    var groupTitle: String?
    var logoUrl: String?
    var streamUrl: String

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
