import GRDB

/// Flat SQLite row for a channel. GRDB needs real columns (not JSON blobs) so
/// the guide/group queries can filter on `hidden` / `groupTitle` / `streamUrl`;
/// conversions to and from the nested domain `ChannelEntity` live alongside.
struct ChannelRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "channels"

    var id: Int64?
    var playlistId: Int64
    var number: Int
    var sortIndex: Int
    var name: String
    var groupTitle: String?
    var logoUrl: String?
    var streamUrl: String
    var tvgId: String?
    var favorite: Bool
    var hidden: Bool
    var favoriteOrder: Int
    var catchupType: String?
    var catchupSource: String?
    var catchupDays: Int?
    var customName: String?
    var audioDecoder: String?
    var videoDecoder: String?
    var epgOffsetMinutes: Int
    var externalPlayer: String?
    var epgOverride: String?

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
