import GRDB

/// Storage boundary for user-created custom groups (Settings → Manage Groups) —
/// the Apple mirror of the Android `RoomCustomGroupStore` + `CustomGroupDao`.
/// Membership rows key on `ChannelImporter.keyOf`, so groups survive playlist
/// refreshes. Names/keys are bound via `arguments:` throughout (never
/// interpolated). The `v5-custom-groups` migration provisions the two tables.
struct CustomGroupStore {
    let db: AppDatabase

    /// Every group in `sortIndex` order, each carrying its member channel keys.
    func all() throws -> [CustomGroup] {
        try db.queue.read { db in
            let groups = try CustomGroupRecord.order(Column("sortIndex"), Column("id")).fetchAll(db)
            let members = try CustomGroupMemberRecord.fetchAll(db)
            var byGroup: [Int64: Set<String>] = [:]
            for member in members { byGroup[member.groupId, default: []].insert(member.channelKey) }
            return groups.map {
                CustomGroup(id: Int($0.id ?? 0), name: $0.name, members: byGroup[$0.id ?? 0] ?? [])
            }
        }
    }

    /// Creates an EMPTY group appended after the last one, returning its new id.
    func create(name: String) throws -> Int {
        try db.queue.write { db in
            let next = try Int.fetchOne(
                db, sql: "SELECT COALESCE(MAX(sortIndex), -1) + 1 FROM custom_groups") ?? 0
            var row = CustomGroupRecord(id: nil, name: name, sortIndex: next)
            try row.insert(db)
            return Int(row.id ?? 0)
        }
    }

    /// Renames the group `id` (Manage Groups: rename).
    func rename(id: Int, name: String) throws {
        try db.queue.write {
            try $0.execute(sql: "UPDATE custom_groups SET name = ? WHERE id = ?", arguments: [name, id])
        }
    }

    /// Deletes the group and its membership in ONE write (Android's
    /// `@Transaction deleteGroup`): members first, then the group row.
    func delete(id: Int) throws {
        try db.queue.write { db in
            try db.execute(sql: "DELETE FROM custom_group_members WHERE groupId = ?", arguments: [id])
            try db.execute(sql: "DELETE FROM custom_groups WHERE id = ?", arguments: [id])
        }
    }

    /// Adds channel keys to the group; already-present keys are no-ops (the
    /// composite primary key dedupes via `INSERT OR IGNORE`).
    func addMembers(id: Int, keys: [String]) throws {
        try db.queue.write { db in
            for key in keys {
                let row = CustomGroupMemberRecord(groupId: Int64(id), channelKey: key)
                try row.insert(db, onConflict: .ignore)
            }
        }
    }
}
