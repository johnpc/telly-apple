import Testing
import Foundation
@testable import Telly

/// The composition-root VOD wiring: ``AppEnvironment/makeVodBrowseModel`` and
/// ``AppEnvironment/makeVodPositionStore`` must build stores over the SHARED
/// database handle, so movies written through one store surface in a browse model
/// built by the factory (proving the DB-handle trick threads a single database).
@MainActor
struct AppEnvironmentVodWiringTests {
    private func env(settings: SettingsStore? = nil) throws -> AppEnvironment {
        AppEnvironment(database: try AppDatabase.makeInMemory(), settings: settings,
                       now: { 1_700_000_000_000 })
    }

    @Test func browseModelReadsMoviesWrittenOnTheSharedHandle() throws {
        let env = try env()
        try VodItemStore(db: env.channelStore.db).replace(playlistId: 1, items: [
            VodItem(id: nil, playlistId: 1, sortIndex: 0, itemKey: "k|A", name: "A",
                    groupTitle: "Action", logoUrl: nil, streamUrl: "http://x/a.mp4"),
        ])
        let model = env.makeVodBrowseModel()
        model.load()
        #expect(!model.isEmpty)
        #expect(model.categories == ["Action"])
        #expect(model.cards.map(\.item.name) == ["A"])
    }

    @Test func positionStoreRemembersByDefaultOnSharedHandle() throws {
        let env = try env()
        let store = env.makeVodPositionStore()
        try store.save(itemKey: "k|A", positionMs: 30_000, durationMs: 90_000)
        #expect(try store.read(itemKey: "k|A") != nil)
    }

    @Test func rememberOffSettingMakesPositionStoreANoOp() throws {
        let settings = SettingsStore(backing: InMemoryKeyValueStore())
        settings.vodRememberPosition = false
        let env = try env(settings: settings)
        let store = env.makeVodPositionStore()
        try store.save(itemKey: "k|A", positionMs: 30_000, durationMs: 90_000)
        #expect(try store.read(itemKey: "k|A") == nil)
        #expect(try store.all().isEmpty)
    }

    @Test func clearVodPositionsEmptiesTheStore() throws {
        let env = try env()
        let store = env.makeVodPositionStore()
        try store.save(itemKey: "k|A", positionMs: 30_000, durationMs: 90_000)
        #expect(try !store.all().isEmpty)
        #expect(env.clearVodPositions() == .success("Playback positions cleared"))
        #expect(try store.all().isEmpty)
    }
}
