#if DEBUG
import Testing
@testable import Telly

/// The DEBUG Movies-browser screenshot harness's pure logic: the `-tellyVodBrowse`
/// flag, the fixture's shape (four movies across two categories with a resume key
/// that matches its item), and the seed persisting `vod_items` plus one mid-band
/// `vod_positions` row — all local, never the real provider.
struct DebugLaunchVodTests {
    @Test func flagSelectsTheRoute() {
        #expect(DebugLaunch.vodBrowseRequested(in: ["Telly", "-tellyVodBrowse"]))
        #expect(!DebugLaunch.vodBrowseRequested(in: ["Telly"]))
        #expect(!DebugLaunch.vodBrowseRequested(in: ["Telly", "-tellyHistorySeed"]))
    }

    @Test func fixtureHasFourMoviesAcrossTwoCategories() {
        let items = DebugLaunch.vodFixture()
        #expect(items.count == 4)
        #expect(Set(items.compactMap(\.groupTitle)) == ["Action", "Drama"])
        #expect(items.map(\.sortIndex) == [0, 1, 2, 3])
        #expect(items.contains { $0.itemKey == DebugLaunch.vodResumeKey })
    }

    @Test func seedPopulatesItemsAndOnePosition() throws {
        let db = try AppDatabase.makeInMemory()
        let items = VodItemStore(db: db)
        let positions = VodPositionStore(db: db, remember: { true }, clock: { 1_700_000_000_000 })
        DebugLaunch.seedVodIfRequested(items: items, positions: positions,
                                       args: ["Telly", "-tellyVodBrowse"])
        #expect(try items.totalCount() == 4)
        #expect(try items.all().map(\.groupTitle) == ["Action", "Action", "Drama", "Drama"])
        let stored = try positions.all()
        #expect(stored.count == 1)
        let resume = try #require(stored.first)
        #expect(resume.itemKey == DebugLaunch.vodResumeKey)
        #expect(VodResumePolicy.offerResume(positionMs: resume.positionMs,
                                            durationMs: resume.durationMs))
    }

    @Test func seedIsNoOpWithoutFlag() throws {
        let db = try AppDatabase.makeInMemory()
        let items = VodItemStore(db: db)
        let positions = VodPositionStore(db: db, remember: { true }, clock: { 0 })
        DebugLaunch.seedVodIfRequested(items: items, positions: positions, args: ["Telly"])
        #expect(try items.totalCount() == 0)
        #expect(try positions.all().isEmpty)
    }
}
#endif
