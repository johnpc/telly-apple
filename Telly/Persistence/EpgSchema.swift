import GRDB

/// The `programs` table — the EPG guide data backing now/next + the grid,
/// mirroring the Android Room `ProgramEntity` schema. The XMLTV programme
/// fields (`ProgramDetails`) flatten to columns so the window/now-next range
/// queries can scan and dedupe on `(channelTvgId, startMs)`.
enum EpgSchema {
    static func createPrograms(_ db: Database) throws {
        try db.create(table: "programs") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("channelTvgId", .text).notNull()
            t.column("startMs", .integer).notNull()
            t.column("endMs", .integer).notNull()
            t.column("title", .text).notNull()
            t.column("subTitle", .text)
            t.column("description", .text)
            t.column("category", .text)
            t.column("episode", .text)
        }
        // Load-bearing: upsert conflict target + covering index for the
        // window/now-next range scans, and the dedupe key for re-imports.
        try db.create(index: "index_programs_channelTvgId_startMs", on: "programs",
                      columns: ["channelTvgId", "startMs"], unique: true)
    }
}
