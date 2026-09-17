import GRDB

/// The `vod_items` + `vod_positions` tables — the Apple mirror of the Android
/// Room VOD schema. `vod_items` holds one row per movie (classified out of the
/// live channels at import time so VOD never pollutes the guide); `sortIndex`
/// fixes playlist order and `itemKey` (`VodClassifier.itemKey`) is the
/// refresh-stable resume identity. `vod_positions` is keyed by that same
/// `itemKey` so a stored position survives playlist refreshes. Purely additive
/// (`v6-vod`): two `CREATE TABLE`s, no alter, no backfill.
enum VodSchema {
    static func createVodItems(_ db: Database) throws {
        try db.create(table: "vod_items") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("playlistId", .integer).notNull()
            t.column("sortIndex", .integer).notNull()
            t.column("itemKey", .text).notNull()
            t.column("name", .text).notNull()
            t.column("groupTitle", .text)
            t.column("logoUrl", .text)
            t.column("streamUrl", .text).notNull()
        }
        try db.create(index: "index_vod_items_playlistId", on: "vod_items", columns: ["playlistId"])
    }

    static func createVodPositions(_ db: Database) throws {
        try db.create(table: "vod_positions") { t in
            t.column("itemKey", .text).notNull().primaryKey()
            t.column("positionMs", .integer).notNull()
            t.column("durationMs", .integer).notNull()
            t.column("updatedAtMs", .integer).notNull()
        }
    }
}
