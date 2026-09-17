import Testing
import GRDB
@testable import Telly

/// The Copy-channels editor model against a REAL in-memory GRDB database:
/// `load()` lists non-hidden channels and defaults the target to the sole group;
/// `commit()` copies the checked channels into the group by refresh-stable key;
/// a re-copy is idempotent; and `commit()` with no target is a no-op.
@MainActor
struct CopyChannelsModelTests {
    private func seed() throws -> (CustomGroupStore, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A"), m("B"), m("C")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        try db.queue.write { try $0.execute(sql: "UPDATE channels SET hidden = 1 WHERE name = 'C'") }
        return (CustomGroupStore(db: db), ChannelStore(db: db))
    }

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://127.0.0.1/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func loadExcludesHiddenAndDefaultsTarget() throws {
        let (groups, channels) = try seed()
        _ = try groups.create(name: "News")
        let model = CopyChannelsModel(store: groups, channelStore: channels)
        model.load()
        #expect(model.channels.map(\.source.name) == ["A", "B"])
        #expect(model.target?.name == "News")
    }

    @Test func commitCopiesCheckedKeys() throws {
        let (groups, channels) = try seed()
        let id = try groups.create(name: "News")
        let model = CopyChannelsModel(store: groups, channelStore: channels)
        model.load()
        let a = try #require(model.channels.first { $0.source.name == "A" })
        model.toggle(a)
        model.commit()
        #expect(try groups.all().first { $0.id == id }?.members == ["A"])
    }

    @Test func reCopyIsIdempotent() throws {
        let (groups, channels) = try seed()
        let id = try groups.create(name: "News")
        let model = CopyChannelsModel(store: groups, channelStore: channels)
        model.load()
        model.toggle(try #require(model.channels.first))
        model.commit()
        model.commit()
        #expect(try groups.all().first { $0.id == id }?.members.count == 1)
    }

    @Test func commitWithNilTargetIsNoOp() throws {
        let (groups, channels) = try seed()          // no groups created → nil target
        let model = CopyChannelsModel(store: groups, channelStore: channels)
        model.load()
        model.toggle(try #require(model.channels.first))
        model.commit()
        #expect(model.target == nil)
        #expect(try groups.all().isEmpty)
    }
}
