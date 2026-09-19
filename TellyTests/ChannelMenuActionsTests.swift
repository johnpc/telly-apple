import Testing
import GRDB
@testable import Telly

/// The pure per-channel menu composition (``ChannelMenuActions``): the rows and
/// their order mirror Android's channel section (favourite toggle, Hide, Assign
/// EPG), and the favourite label flips on the channel's favourite state while
/// Hide / Assign EPG stay fixed. Also pins the composition-root wiring of the
/// row menu's Assign-EPG picker factory.
struct ChannelMenuActionsTests {
    private func ch(favorite: Bool = false) -> ChannelEntity {
        ChannelEntity(id: 1, playlistId: 1, number: 1, sortIndex: 1,
                      source: ChannelSource(name: "News HD", streamUrl: "http://x/1"),
                      flags: ChannelFlags(favorite: favorite))
    }

    @Test func actionsMatchAndroidChannelSectionOrder() {
        #expect(ChannelMenuActions.actions(for: ch()) == [.toggleFavorite, .hide, .assignEpg])
    }

    @Test func favoriteLabelFlipsOnState() {
        #expect(ChannelMenuActions.label(.toggleFavorite, for: ch(favorite: false)) == "Add to Favorites")
        #expect(ChannelMenuActions.label(.toggleFavorite, for: ch(favorite: true)) == "Remove from Favorites")
    }

    @Test func hideAndAssignLabelsAreFixed() {
        #expect(ChannelMenuActions.label(.hide, for: ch()) == "Hide channel")
        #expect(ChannelMenuActions.label(.hide, for: ch(favorite: true)) == "Hide channel")
        #expect(ChannelMenuActions.label(.assignEpg, for: ch()) == "Assign EPG")
    }

    @MainActor @Test func environmentVendsAssignEpgPickerForChannel() throws {
        let db = try AppDatabase.makeInMemory()
        let env = AppEnvironment(database: db)
        _ = try env.playlistStore.add(
            sourceUrl: "u",
            playlist: M3uPlaylist(channels: [
                M3uChannel(title: "A", streamURL: "http://x/a", tvgID: "a", tvgName: nil,
                           tvgLogo: nil, groupTitle: "G", catchup: nil,
                           catchupSource: nil, catchupDays: nil)]),
            name: nil, nowMs: 0)
        let channel = try #require(try env.channelStore.allChannels().first)
        let picker = env.makeAssignEpgModel(for: channel)
        #expect(picker.channel.id == channel.id)
        picker.select("a")
        #expect(try env.channelStore.allChannels().first?.overrides.epgOverride == "a")
    }
}
