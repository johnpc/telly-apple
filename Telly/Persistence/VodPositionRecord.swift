import GRDB

/// Flat SQLite row for one stored resume position — the Apple mirror of the
/// Android `VodPositionEntity`. A natural string primary key (`itemKey`) means
/// no autoincrement, so this is a plain `PersistableRecord`. Conversions to and
/// from the domain `VodPosition` live in `VodPositionRecord+Entity`.
struct VodPositionRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "vod_positions"

    var itemKey: String
    var positionMs: Int64
    var durationMs: Int64
    var updatedAtMs: Int64
}
