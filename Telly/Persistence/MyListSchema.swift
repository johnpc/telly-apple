import GRDB

/// The `my_list` table — the Apple mirror of the Android `my_list` Room table.
/// One row per saved programme: a SNAPSHOT of the airing (title/description/
/// times) plus a REFERENCE to its channel via the refresh-stable
/// `ChannelImporter.keyOf`. Identity is the composite `(channelKey, startMs)`,
/// so re-saving an airing replaces it. Purely additive (`v7-mylist`): one
/// `CREATE TABLE`, no alter, no backfill.
enum MyListSchema {
    static func createMyList(_ db: Database) throws {
        try db.create(table: "my_list") { t in
            t.column("channelKey", .text).notNull()
            t.column("startMs", .integer).notNull()
            t.column("endMs", .integer).notNull()
            t.column("title", .text).notNull()
            t.column("description", .text)
            t.column("addedAtMs", .integer).notNull()
            t.primaryKey(["channelKey", "startMs"])
        }
        try db.create(index: "index_my_list_addedAtMs", on: "my_list", columns: ["addedAtMs"])
    }
}
