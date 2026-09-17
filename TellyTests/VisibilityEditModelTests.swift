import Testing
import GRDB
@testable import Telly

/// The bulk Manage-Visibility editor model: lists every channel (hidden
/// included) and persists a toggled hidden flag.
@MainActor
struct VisibilityEditModelTests {
    private func seed() throws -> ChannelStore {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A"), m("B"), m("C")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        try db.queue.write { try $0.execute(sql: "UPDATE channels SET hidden = 1 WHERE name = 'B'") }
        return ChannelStore(db: db)
    }

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    @Test func listsAllChannelsIncludingHidden() throws {
        let model = VisibilityEditModel(store: try seed())
        model.load()
        #expect(model.channels.map(\.source.name) == ["A", "B", "C"])
    }

    @Test func toggleHiddenPersistsAndReloads() throws {
        let store = try seed()
        let model = VisibilityEditModel(store: store)
        model.load()
        let a = try #require(model.channels.first { $0.source.name == "A" })
        model.toggleHidden(a)                      // hide A
        #expect(model.channels.first { $0.source.name == "A" }?.flags.hidden == true)
        #expect(try store.visibleChannels().map(\.source.name) == ["C"])
    }
}
