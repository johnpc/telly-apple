import GRDB

/// The `custom_groups` + `custom_group_members` tables — user-created named
/// containers with arbitrary membership, the Apple mirror of the Android Room
/// `CustomGroupEntity` / `CustomGroupMemberEntity`. Membership is keyed by the
/// refresh-stable `ChannelImporter.keyOf` (`channelKey`) so a group survives
/// playlist refreshes exactly like favourite/hidden flags. Purely additive
/// (`v5-custom-groups`): two `CREATE TABLE`s, no alter, no backfill.
enum CustomGroupSchema {
    static func createCustomGroups(_ db: Database) throws {
        try db.create(table: "custom_groups") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("sortIndex", .integer).notNull()
        }
    }

    static func createCustomGroupMembers(_ db: Database) throws {
        try db.create(table: "custom_group_members") { t in
            t.column("groupId", .integer).notNull()
            t.column("channelKey", .text).notNull()
            t.primaryKey(["groupId", "channelKey"])
        }
    }
}
