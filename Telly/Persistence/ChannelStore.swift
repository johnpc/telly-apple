import GRDB

/// One row of the guide's group list: a group name plus its channel count.
struct ChannelGroupCount: Equatable {
    let groupTitle: String?
    let channelCount: Int
}

/// Read queries over the `channels` table, shaped for the guide/group UI —
/// the Apple mirror of the Android `ChannelDao`.
struct ChannelStore {
    let db: AppDatabase

    /// A playlist's channels in channel-number order (hidden included).
    func channels(playlistId: Int) throws -> [ChannelEntity] {
        try fetch("SELECT * FROM channels WHERE playlistId = ? ORDER BY number", [playlistId])
    }

    /// Visible channels of one group, in reorder/sort order.
    func channels(playlistId: Int, groupTitle: String) throws -> [ChannelEntity] {
        try fetch("SELECT * FROM channels WHERE playlistId = ? AND groupTitle = ? AND hidden = 0 " +
                  "ORDER BY sortIndex, number", [playlistId, groupTitle])
    }

    /// All visible channels across playlists in "All channels" zap order.
    func visibleChannels() throws -> [ChannelEntity] {
        try fetch("SELECT * FROM channels WHERE hidden = 0 ORDER BY sortIndex, number", [])
    }

    /// Every channel, hidden included — the bulk visibility/blocking editors.
    func allChannels() throws -> [ChannelEntity] {
        try fetch("SELECT * FROM channels ORDER BY number", [])
    }

    func totalCount() throws -> Int {
        try db.queue.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM channels") ?? 0 }
    }

    /// Visible-channel counts per group, ordered by first appearance.
    func groups(playlistId: Int) throws -> [ChannelGroupCount] {
        try db.queue.read { db in
            try Row.fetchAll(db, sql: "SELECT groupTitle, COUNT(*) AS channelCount FROM channels " +
                "WHERE playlistId = ? AND hidden = 0 GROUP BY groupTitle ORDER BY MIN(sortIndex)",
                arguments: [playlistId])
                .map { ChannelGroupCount(groupTitle: $0["groupTitle"], channelCount: $0["channelCount"]) }
        }
    }

    private func fetch(_ sql: String, _ args: [DatabaseValueConvertible]) throws -> [ChannelEntity] {
        try db.queue.read {
            try ChannelRecord.fetchAll($0, sql: sql, arguments: StatementArguments(args)).map(\.entity)
        }
    }
}
