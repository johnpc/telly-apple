import Testing
import GRDB
@testable import Telly

/// The composition-root wiring for the guide grid: `makeGuideGridModel` must
/// build a model over the environment's real channel + programme stores, so a
/// seeded in-memory environment yields populated rows on `load()`.
@MainActor
struct AppEnvironmentGuideWiringTests {
    @Test func makeGuideGridModelLoadsRowsFromSeededStores() throws {
        let db = try AppDatabase.makeInMemory()
        let env = AppEnvironment(database: db)
        _ = try env.playlistStore.add(
            sourceUrl: "u",
            playlist: M3uPlaylist(channels: [
                M3uChannel(title: "A", streamURL: "http://x/a", tvgID: "a", tvgName: nil,
                           tvgLogo: nil, groupTitle: "G", catchup: nil,
                           catchupSource: nil, catchupDays: nil)]),
            name: nil, nowMs: 0)
        let model = env.makeGuideGridModel()
        model.load()
        #expect(model.channels.count == 1)
        #expect(model.rows.count == 1)
        #expect(model.rows[0].channel.epgId == "a")
    }

    @Test func makeGuideGridModelReflectsClockSetting() throws {
        let db = try AppDatabase.makeInMemory()
        let store = SettingsStore(backing: InMemoryKeyValueStore())
        store.use24hClock = false
        let env = AppEnvironment(database: db, settings: store)
        #expect(env.makeGuideGridModel().is24h == false)
    }
}
