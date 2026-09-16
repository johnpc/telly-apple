import GRDB

/// The `playlists` + `channels` tables — the core of the onboarding →
/// channel-list → guide vertical, mirroring the Android Room schema
/// (embedded `ChannelSource`/`ChannelFlags`/`ChannelCatchup`/`ChannelOverrides`
/// flatten to columns so the group/guide queries can filter on them).
enum CoreSchema {
    static func createPlaylists(_ db: Database) throws {
        try db.create(table: "playlists") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("url", .text).notNull()
            t.column("epgUrl", .text)
            t.column("lastUpdatedMs", .integer).notNull().defaults(to: 0)
            t.column("epgLastUpdatedMs", .integer).notNull().defaults(to: 0)
            t.uniqueKey(["url"])
        }
    }

    static func createChannels(_ db: Database) throws {
        try db.create(table: "channels") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("playlistId", .integer).notNull()
                .references("playlists", onDelete: .cascade)
            t.column("number", .integer).notNull()
            t.column("sortIndex", .integer).notNull()
            t.column("name", .text).notNull()
            t.column("groupTitle", .text)
            t.column("logoUrl", .text)
            t.column("streamUrl", .text).notNull()
            t.column("tvgId", .text)
            t.column("favorite", .boolean).notNull().defaults(to: false)
            t.column("hidden", .boolean).notNull().defaults(to: false)
            t.column("favoriteOrder", .integer).notNull().defaults(to: 0)
            t.column("blocked", .boolean).notNull().defaults(to: false)
            t.column("catchupType", .text)
            t.column("catchupSource", .text)
            t.column("catchupDays", .integer)
            t.column("customName", .text)
            t.column("audioDecoder", .text)
            t.column("videoDecoder", .text)
            t.column("epgOffsetMinutes", .integer).notNull().defaults(to: 0)
            t.column("externalPlayer", .text)
            t.column("epgOverride", .text)
        }
        try db.create(index: "index_channels_playlistId", on: "channels", columns: ["playlistId"])
    }
}
