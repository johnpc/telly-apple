import Testing
import GRDB
@testable import Telly

/// Guards the shipped v1-core catch-up columns (`catchupType`/`catchupSource`/
/// `catchupDays`): a `ChannelEntity` carrying populated catch-up fields
/// round-trips through the on-disk row unchanged, with no schema/migration work.
struct ChannelCatchupPersistenceTests {
    @Test func catchupFieldsRoundTripThroughTheChannelsTable() throws {
        let db = try AppDatabase.makeInMemory()
        try db.queue.write { db in
            try db.execute(sql: "INSERT INTO playlists (id, name, url) VALUES (1, 'P', 'u')")
        }
        let source = ChannelSource(name: "News", groupTitle: "Info", logoUrl: nil,
                                   streamUrl: "http://x/news", tvgId: "news.tv")
        let catchup = ChannelCatchup(catchupType: "shift",
                                     catchupSource: "http://x/archive?utc=${start}",
                                     catchupDays: 5)
        let channel = ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                                    source: source, catchup: catchup)

        let id = try db.queue.write { db -> Int64 in
            var record = ChannelRecord(channel)
            try record.insert(db)
            return record.id!
        }
        let reloaded = try db.queue.read { try ChannelRecord.fetchOne($0, key: id) }

        let entity = try #require(reloaded?.entity)
        #expect(entity.catchup == catchup)
        #expect(entity.catchup.catchupType == "shift")
        #expect(entity.catchup.catchupSource == "http://x/archive?utc=${start}")
        #expect(entity.catchup.catchupDays == 5)
        #expect(entity.catchupAttributes()?.type == .shift)
    }
}
