import GRDB

/// Read/write queries over the `programs` table, shaped for the guide's window
/// and now/next lookups — the Apple mirror of the Android `ProgramDao`. Times
/// are stored as-imported; per-channel EPG offsets are applied above this layer
/// (see `EpgRepository`), so every query here works purely on real epoch millis.
struct ProgramStore {
    let db: AppDatabase

    /// Programmes overlapping `[fromMs, toMs)` on the given channels, ordered by
    /// `(channelTvgId, startMs)` — the grid window (`endMs > from AND start < to`).
    func window(tvgIds: [String], fromMs: Int, toMs: Int) throws -> [ProgramEntity] {
        try inQuery(tvgIds, "AND endMs > ? AND startMs < ? ORDER BY channelTvgId, startMs",
                    [Int64(fromMs), Int64(toMs)])
    }

    /// Programmes still airing or upcoming at `atMs` on the given channels, in
    /// `(channelTvgId, startMs)` order — the now/next feed (`endMs > at`).
    func airingOrUpcoming(tvgIds: [String], atMs: Int) throws -> [ProgramEntity] {
        try inQuery(tvgIds, "AND endMs > ? ORDER BY channelTvgId, startMs", [Int64(atMs)])
    }

    /// Programmes whose title word-prefix matches `titleLike` (a `SearchQuery`
    /// LIKE pattern compared against `' ' || title`, ESCAPE '\') and are still
    /// airing or upcoming at `atMs`, soonest first — the search feed. `limit`
    /// bounds the leading-wildcard scan (Android `SearchDao.programs`).
    func searchTitles(titleLike: String, atMs: Int, limit: Int) throws -> [ProgramEntity] {
        let sql = "SELECT * FROM programs WHERE endMs > ? AND (' ' || title) LIKE ? ESCAPE '\\' "
            + "ORDER BY startMs, channelTvgId LIMIT ?"
        return try db.queue.read {
            let args: [DatabaseValueConvertible] = [atMs, titleLike, limit]
            return try ProgramRecord.fetchAll($0, sql: sql, arguments: StatementArguments(args)).map(\.entity)
        }
    }

    /// Distinct channel tvg-ids that currently hold programmes, sorted.
    func channelIds() throws -> [String] {
        try db.queue.read {
            try String.fetchAll($0, sql: "SELECT DISTINCT channelTvgId FROM programs ORDER BY channelTvgId")
        }
    }

    /// Replaces the stored programmes for every channel present in `document`:
    /// stale rows for those channels are deleted, then the document's rows are
    /// inserted with `.replace` (so the last source wins per channel). Channels
    /// absent from `document` keep their rows. `keepDescriptions == false` drops
    /// each programme's description on the way in.
    func upsertReplacing(document: XmltvDocument, keepDescriptions: Bool) throws {
        try db.queue.write { db in
            try deleteChannels(db, Set(document.programs.map(\.channelId)))
            for program in document.programs {
                var record = ProgramRecord(ProgramEntity(
                    channelTvgId: program.channelId, startMs: program.startMs,
                    endMs: program.endMs, details: program.details))
                if !keepDescriptions { record.description = nil }
                try record.insert(db, onConflict: .replace)
            }
        }
    }

    /// Deletes programmes that ended before `cutoffMs` (the past-window trim).
    func trimEndedBefore(cutoffMs: Int) throws {
        try db.queue.write {
            try $0.execute(sql: "DELETE FROM programs WHERE endMs < ?", arguments: [Int64(cutoffMs)])
        }
    }

    /// Runs a `channelTvgId IN (…)` read with a trailing predicate and its bound
    /// args, mapping rows to domain programmes; empty `tvgIds` short-circuits.
    private func inQuery(_ tvgIds: [String], _ tail: String,
                         _ bounds: [DatabaseValueConvertible]) throws -> [ProgramEntity] {
        guard !tvgIds.isEmpty else { return [] }
        let sql = "SELECT * FROM programs WHERE channelTvgId IN (\(databaseQuestionMarks(count: tvgIds.count))) " + tail
        let args = tvgIds.map { $0 as DatabaseValueConvertible } + bounds
        return try db.queue.read {
            try ProgramRecord.fetchAll($0, sql: sql, arguments: StatementArguments(args)).map(\.entity)
        }
    }

    /// Deletes every row belonging to the given channels (no-op when empty).
    private func deleteChannels(_ db: Database, _ channelIds: Set<String>) throws {
        guard !channelIds.isEmpty else { return }
        try db.execute(
            sql: "DELETE FROM programs WHERE channelTvgId IN (\(databaseQuestionMarks(count: channelIds.count)))",
            arguments: StatementArguments(Array(channelIds)))
    }
}
