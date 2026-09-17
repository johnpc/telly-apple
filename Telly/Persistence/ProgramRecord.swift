import GRDB

/// Flat SQLite row for one guide programme. GRDB needs real columns (not a JSON
/// blob) so the window/now-next queries can range-scan on `startMs`/`endMs` and
/// dedupe on `(channelTvgId, startMs)`; conversions to and from the nested
/// domain `ProgramEntity` live alongside.
struct ProgramRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "programs"

    var id: Int64?
    var channelTvgId: String
    var startMs: Int64
    var endMs: Int64
    var title: String
    var subTitle: String?
    var description: String?
    var category: String?
    var episode: String?

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
