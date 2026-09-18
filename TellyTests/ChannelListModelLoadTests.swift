import Testing
import GRDB
@testable import Telly

/// The channel list's load lifecycle against an in-memory store and injected
/// refresh: cached rows load at once, an empty store shows the skeleton then
/// resolves to loaded/empty/failed, and Retry re-invokes the refresh.
@MainActor
struct ChannelListModelLoadTests {
    struct Boom: Error {}

    private func make() throws -> (ChannelListModel, PlaylistStore) {
        let db = try AppDatabase.makeInMemory()
        return (ChannelListModel(store: ChannelStore(db: db)), PlaylistStore(db: db))
    }

    private func seed(_ store: PlaylistStore, _ name: String) {
        let channel = M3uChannel(title: name, streamURL: "http://x/\(name).ts", tvgID: name,
                                 tvgName: nil, tvgLogo: nil, groupTitle: "Live",
                                 catchup: nil, catchupSource: nil, catchupDays: nil)
        _ = try? store.add(sourceUrl: "u", playlist: M3uPlaylist(channels: [channel]),
                           name: nil, nowMs: 0)
    }

    @Test func emptyStoreWhoseRefreshImportsChannelsEndsLoaded() async throws {
        let (model, store) = try make()
        model.refresh = { seed(store, "a") }
        await model.start()
        #expect(model.phase == .loaded)
        #expect(model.channels.count == 1)
    }

    @Test func emptyStoreWithNoOpRefreshResolvesEmpty() async throws {
        let (model, _) = try make()
        await model.start()
        #expect(model.phase == .empty)
    }

    @Test func emptyStoreWithFailingRefreshResolvesFailed() async throws {
        let (model, _) = try make()
        model.refresh = { throw Boom() }
        await model.start()
        #expect(model.phase == .failed)
    }

    @Test func cachedChannelsLoadImmediately() async throws {
        let (model, store) = try make()
        seed(store, "a")
        await model.start()
        #expect(model.phase == .loaded)
        #expect(model.channels.count == 1)
    }

    @Test func retryReinvokesRefreshAndRecovers() async throws {
        let (model, store) = try make()
        var calls = 0
        model.refresh = { calls += 1; if calls > 1 { seed(store, "a") } }
        await model.start()          // 1st: store still empty → failed/empty
        #expect(model.phase == .empty)
        await model.retry()          // 2nd: imports a channel → loaded
        #expect(calls == 2)
        #expect(model.phase == .loaded)
    }
}
