import GRDB

/// The `epg_sources` table — user-added (custom) EPG sources per playlist,
/// mirroring the Android Room `EpgSourceEntity`. The `(playlistUrl, url)`
/// unique index makes a re-add of the same URL a no-op (`INSERT … onConflict:
/// .ignore`); the auto-detected source stays on `playlists.epgUrl`.
enum EpgSourceSchema {
    static func createEpgSources(_ db: Database) throws {
        try db.create(table: "epg_sources") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("playlistUrl", .text).notNull()
            t.column("url", .text).notNull()
            t.column("addedAtMs", .integer).notNull()
        }
        try db.create(index: "index_epg_sources_playlistUrl_url", on: "epg_sources",
                      columns: ["playlistUrl", "url"], unique: true)
    }
}
