import Testing
import CoreGraphics
import Foundation
import GRDB
@testable import Telly

/// The guide grid's load lifecycle: an empty grid shows the skeleton then
/// resolves (empty / failed / loaded once its refresh imports channels), and
/// Retry re-invokes the refresh. Seeded channels load straight to `loaded`.
@MainActor
struct GuideGridModelLoadTests {
    struct Boom: Error {}

    private func make() throws -> (GuideGridModel, PlaylistStore) {
        let db = try AppDatabase.makeInMemory()
        let model = GuideGridModel(channelStore: ChannelStore(db: db),
                                   repository: EpgRepository(store: ProgramStore(db: db)),
                                   now: { 0 }, timeZone: TimeZone(identifier: "UTC")!, is24h: true)
        return (model, PlaylistStore(db: db))
    }

    private func seed(_ store: PlaylistStore) {
        let channel = M3uChannel(title: "A", streamURL: "http://x/a.ts", tvgID: "a", tvgName: nil,
                                 tvgLogo: nil, groupTitle: "Live", catchup: nil,
                                 catchupSource: nil, catchupDays: nil)
        _ = try? store.add(sourceUrl: "u", playlist: M3uPlaylist(channels: [channel]),
                           name: nil, nowMs: 0)
    }

    @Test func emptyGridResolvesEmpty() async throws {
        let (model, _) = try make()
        await model.start()
        #expect(model.phase == .empty)
    }

    @Test func emptyGridWithFailingRefreshIsFailed() async throws {
        let (model, _) = try make()
        model.refresh = { throw Boom() }
        await model.start()
        #expect(model.phase == .failed)
    }

    @Test func refreshThatImportsChannelsEndsLoaded() async throws {
        let (model, store) = try make()
        model.refresh = { seed(store) }
        await model.start()
        #expect(model.phase == .loaded)
        #expect(!model.rows.isEmpty)
    }

    @Test func seededGridLoadsImmediately() async throws {
        let (model, store) = try make()
        seed(store)
        await model.start()
        #expect(model.phase == .loaded)
    }

    @Test func retryReinvokesRefresh() async throws {
        let (model, _) = try make()
        var calls = 0
        model.refresh = { calls += 1 }
        await model.start()
        await model.retry()
        #expect(calls == 2)
    }
}
