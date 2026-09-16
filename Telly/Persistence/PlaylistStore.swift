import GRDB

/// Stores user playlists and (re)imports their channels — the Apple mirror of
/// the Android `RoomPlaylistRepository`: numbers follow playlist order and
/// favorite/override state survives re-adds via `ChannelImporter`. Timestamps
/// are passed in, so there are no wall-clock reads in logic.
struct PlaylistStore {
    let db: AppDatabase

    /// All stored playlists, in insertion order.
    func all() throws -> [PlaylistEntity] {
        try db.queue.read { try PlaylistEntity.order(Column("id")).fetchAll($0) }
    }

    /// Adds/refreshes the playlist at `sourceUrl`; a re-add replaces its
    /// channels while carrying user flags/overrides forward. Returns the id.
    @discardableResult
    func add(sourceUrl: String, playlist: M3uPlaylist, name: String?, nowMs: Int64) throws -> Int64 {
        try db.queue.write { db in
            let existing = try PlaylistEntity.filter(Column("url") == sourceUrl).fetchOne(db)
            let previous = try existing.map {
                try ChannelRecord.filter(Column("playlistId") == $0.id).fetchAll(db).map(\.entity)
            } ?? []
            var row = PlaylistEntity(
                id: existing?.id, name: name ?? existing?.name ?? Self.nameFor(sourceUrl),
                url: sourceUrl, epgUrl: playlist.epgURL, lastUpdatedMs: nowMs,
                epgLastUpdatedMs: existing?.epgLastUpdatedMs ?? 0)
            try row.save(db)
            let playlistId = row.id ?? 0
            try ChannelRecord.filter(Column("playlistId") == playlistId).deleteAll(db)
            let imported = ChannelImporter.importChannels(
                playlistId: Int(playlistId), parsed: playlist.channels, previous: previous)
            for channel in imported {
                var record = ChannelRecord(channel)
                try record.insert(db)
            }
            return playlistId
        }
    }

    /// Renames the playlist stored under `sourceUrl`.
    func rename(sourceUrl: String, name: String) throws {
        try db.queue.write {
            try $0.execute(sql: "UPDATE playlists SET name = ? WHERE url = ?", arguments: [name, sourceUrl])
        }
    }

    /// Re-keys the playlist from `oldUrl` to `newUrl` in place, keeping its id
    /// and channels. False when `oldUrl` is unknown or `newUrl` is already taken.
    @discardableResult
    func changeUrl(oldUrl: String, newUrl: String) throws -> Bool {
        try db.queue.write { db in
            let free = try PlaylistEntity.filter(Column("url") == newUrl).fetchOne(db) == nil
            let present = try PlaylistEntity.filter(Column("url") == oldUrl).fetchOne(db) != nil
            guard free, present else { return false }
            try db.execute(sql: "UPDATE playlists SET url = ? WHERE url = ?", arguments: [newUrl, oldUrl])
            return true
        }
    }

    /// Deletes the playlist stored under `sourceUrl`; its channels cascade.
    func delete(sourceUrl: String) throws {
        try db.queue.write { _ = try PlaylistEntity.filter(Column("url") == sourceUrl).deleteAll($0) }
    }

    /// A human-readable default name: the URL's last path segment.
    static func nameFor(_ sourceUrl: String) -> String {
        let path = sourceUrl.split(separator: "?", maxSplits: 1)[0]
        let segment = path.split(separator: "/").last.map(String.init) ?? ""
        return segment.isEmpty ? sourceUrl : segment
    }
}
