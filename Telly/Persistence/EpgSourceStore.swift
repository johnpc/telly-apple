import GRDB

/// Storage boundary for custom EPG sources (Settings → EPG → EPG sources) — the
/// Apple mirror of the Android `RoomEpgSourceStore`. Timestamps are passed in,
/// so there are no wall-clock reads in logic; rows key on the playlist's stable
/// URL so they survive playlist re-imports. SQL uses `arguments:` throughout.
struct EpgSourceStore {
    let db: AppDatabase

    /// Every custom source, in the order it was added.
    func all() throws -> [EpgSource] {
        try db.queue.read {
            try EpgSourceEntity.order(Column("addedAtMs"), Column("id")).fetchAll($0).map(Self.source)
        }
    }

    /// The custom sources of one playlist, in fetch (added) order.
    func forPlaylist(_ playlistUrl: String) throws -> [EpgSource] {
        try db.queue.read {
            try EpgSourceEntity
                .filter(Column("playlistUrl") == playlistUrl)
                .order(Column("addedAtMs"), Column("id"))
                .fetchAll($0).map(Self.source)
        }
    }

    /// Adds `url` for the playlist; re-adding the same URL is ignored (the
    /// `(playlistUrl, url)` unique index dedupes) so no duplicate row appears.
    func add(playlistUrl: String, url: String, nowMs: Int64) throws {
        try db.queue.write {
            var row = EpgSourceEntity(id: nil, playlistUrl: playlistUrl, url: url, addedAtMs: nowMs)
            try row.insert($0, onConflict: .ignore)
        }
    }

    /// Rewrites the URL of the source `id` (settings: edit source).
    func setUrl(id: Int64, url: String) throws {
        try db.queue.write {
            try $0.execute(sql: "UPDATE epg_sources SET url = ? WHERE id = ?", arguments: [url, id])
        }
    }

    /// Deletes the source `id` (settings: delete source).
    func remove(id: Int64) throws {
        try db.queue.write {
            try $0.execute(sql: "DELETE FROM epg_sources WHERE id = ?", arguments: [id])
        }
    }

    /// Follows a playlist URL edit: re-keys its custom sources in place.
    func rekeyPlaylist(oldUrl: String, newUrl: String) throws {
        try db.queue.write {
            try $0.execute(sql: "UPDATE epg_sources SET playlistUrl = ? WHERE playlistUrl = ?",
                           arguments: [newUrl, oldUrl])
        }
    }

    private static func source(_ row: EpgSourceEntity) -> EpgSource {
        EpgSource(id: row.id ?? 0, playlistUrl: row.playlistUrl, url: row.url)
    }
}
