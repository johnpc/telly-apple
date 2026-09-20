import Testing
import CoreGraphics
import Foundation
import GRDB
@testable import Telly

/// The guide grid's interactive group filter: the chip-strip group list (shared
/// with the channel list, custom groups appended last), row filtering per the
/// selected group, "All channels" showing everything, an empty group yielding no
/// rows, pseudo-group visibility, and the global playlist-group filter applied.
@MainActor
struct GuideGridModelGroupsTests {
    private func ch(_ name: String, _ group: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    /// A loaded model over three channels in two playlist groups (News: A, B;
    /// Sport: C) at a fixed UTC clock, optionally behind a group `filter`.
    private func makeModel(
        filter: @escaping ([ChannelEntity]) -> [ChannelEntity] = { $0 }
    ) throws -> GuideGridModel {
        let db = try AppDatabase.makeInMemory()
        _ = try PlaylistStore(db: db).add(
            sourceUrl: "u",
            playlist: M3uPlaylist(channels: [ch("A", "News"), ch("B", "News"), ch("C", "Sport")]),
            name: nil, nowMs: 0)
        let model = GuideGridModel(
            channelStore: ChannelStore(db: db),
            repository: EpgRepository(store: ProgramStore(db: db)),
            now: { 3_600_000 }, timeZone: TimeZone(identifier: "UTC")!, is24h: true,
            filter: filter)
        model.load()
        return model
    }

    private func names(_ model: GuideGridModel) -> [String] {
        model.rows.map(\.channel.source.name)
    }

    @Test func groupsLeadWithFavoritesThenAllThenPlaylistGroups() throws {
        #expect(try makeModel().groups == ["Favorites", "All channels", "News", "Sport"])
    }

    @Test func allChannelsShowsEveryRow() throws {
        #expect(try names(makeModel()) == ["A", "B", "C"])
    }

    @Test func selectGroupFiltersRowsLive() throws {
        let model = try makeModel()
        model.selectGroup("News")
        #expect(names(model) == ["A", "B"])
        model.selectGroup("Sport")
        #expect(names(model) == ["C"])
        model.selectGroup(ChannelPanelGroups.allChannels)
        #expect(names(model) == ["A", "B", "C"])
    }

    @Test func emptyGroupYieldsNoRowsWithoutCrashing() throws {
        let model = try makeModel()
        model.selectGroup("Favorites")  // no favourites seeded
        #expect(model.rows.isEmpty)
        #expect(model.focus == nil)
    }

    @Test func visibilityOffDropsPseudoGroup() throws {
        let model = try makeModel()
        model.visibility.favorites = false
        #expect(!model.groups.contains("Favorites"))
        #expect(model.groups.contains("All channels"))
    }

    @Test func customGroupListedLastAndSelectableToItsMembers() throws {
        let model = try makeModel()
        let groups = CustomGroupStore(db: model.channelStore.db)
        let id = try groups.create(name: "Kids")
        try groups.addMembers(id: id, keys: ["A", "C"])  // keyOf == tvg-id here
        model.load()  // reloads custom groups alongside channels
        #expect(model.groups == ["Favorites", "All channels", "News", "Sport", "Kids"])
        model.selectGroup("Kids")
        #expect(names(model) == ["A", "C"])
    }

    @Test func globalFilterExcludesChannelsFromGroupsAndRows() throws {
        // A composition-root style filter that hides the whole "Sport" group.
        let model = try makeModel { $0.filter { $0.source.groupTitle != "Sport" } }
        #expect(model.groups == ["Favorites", "All channels", "News"])
        #expect(names(model) == ["A", "B"])
    }
}
