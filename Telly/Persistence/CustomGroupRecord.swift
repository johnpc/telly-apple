import GRDB

/// Flat SQLite row for one custom group — the Apple mirror of the Android
/// `CustomGroupEntity`. `sortIndex` fixes the group order; `id` is filled on
/// insert (autoincrement) via `didInsert`.
struct CustomGroupRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "custom_groups"

    var id: Int64?
    var name: String
    var sortIndex: Int

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

/// One membership row: a `channelKey` (`ChannelImporter.keyOf`) in a group —
/// the Apple mirror of the Android `CustomGroupMemberEntity`. The composite
/// primary key `(groupId, channelKey)` makes a re-add idempotent.
struct CustomGroupMemberRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "custom_group_members"

    var groupId: Int64
    var channelKey: String
}
