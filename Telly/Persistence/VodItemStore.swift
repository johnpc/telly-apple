import GRDB

/// Storage boundary for imported VOD movies — the Apple mirror of the Android
/// VOD item DAO. `replace(playlistId:items:)` swaps exactly one playlist's rows
/// in a single write (delete-for-playlist + insert), so re-adding a playlist
/// refreshes its movies without touching any other playlist's. All predicates
/// bind via GRDB column expressions (never string interpolation).
struct VodItemStore {
    let db: AppDatabase

    /// Every movie across all playlists, in playlist order.
    func all() throws -> [VodItem] {
        try db.queue.read {
            try VodItemRecord.order(Column("sortIndex"), Column("id")).fetchAll($0).map(\.entity)
        }
    }

    /// The movie with this refresh-stable `itemKey`, or nil.
    func byKey(_ itemKey: String) throws -> VodItem? {
        try db.queue.read {
            try VodItemRecord.filter(Column("itemKey") == itemKey).fetchOne($0)?.entity
        }
    }

    /// Total number of stored movies (wizard/summary count).
    func totalCount() throws -> Int {
        try db.queue.read { try VodItemRecord.fetchCount($0) }
    }

    /// Replaces `playlistId`'s movies with `items` in ONE write: delete this
    /// playlist's rows, then insert the fresh set.
    func replace(playlistId: Int, items: [VodItem]) throws {
        try db.queue.write { db in
            try VodItemRecord.filter(Column("playlistId") == playlistId).deleteAll(db)
            for item in items {
                var record = VodItemRecord(item)
                try record.insert(db)
            }
        }
    }
}
