import Testing
@testable import Telly

/// The pure group filter: an ungrouped channel and one from an unknown playlist
/// are always kept; a grouped channel from a known playlist is dropped only when
/// its group is disabled. Mirrors the Android `PlaylistGroupFilter` contract.
struct PlaylistGroupFilterTests {
    private func channel(_ name: String, playlistId: Int, group: String?) -> ChannelEntity {
        ChannelEntity(playlistId: playlistId, number: 1, sortIndex: 0,
                      source: ChannelSource(name: name, groupTitle: group,
                                            logoUrl: nil, streamUrl: "http://x/\(name)", tvgId: name))
    }

    @Test func keepsUngroupedChannelEvenWhenPlaylistKnown() {
        let channels = [channel("A", playlistId: 1, group: nil)]
        let kept = PlaylistGroupFilter.visible(channels, playlistUrlById: [1: "u"],
                                               groupEnabled: { _, _ in false })
        #expect(kept.map(\.source.name) == ["A"])
    }

    @Test func keepsChannelFromUnknownPlaylist() {
        let channels = [channel("A", playlistId: 9, group: "Sport")]
        let kept = PlaylistGroupFilter.visible(channels, playlistUrlById: [1: "u"],
                                               groupEnabled: { _, _ in false })
        #expect(kept.map(\.source.name) == ["A"])
    }

    @Test func dropsDisabledGroupKeepsEnabled() {
        let channels = [channel("A", playlistId: 1, group: "Sport"),
                        channel("B", playlistId: 1, group: "News")]
        let kept = PlaylistGroupFilter.visible(channels, playlistUrlById: [1: "u"],
                                               groupEnabled: { _, group in group == "News" })
        #expect(kept.map(\.source.name) == ["B"])
    }

    @Test func passesResolvedUrlAndGroupToPredicate() {
        let channels = [channel("A", playlistId: 1, group: "Sport")]
        var seen: (String, String)?
        _ = PlaylistGroupFilter.visible(channels, playlistUrlById: [1: "http://h/p.m3u"],
                                        groupEnabled: { url, group in seen = (url, group); return true })
        #expect(seen?.0 == "http://h/p.m3u")
        #expect(seen?.1 == "Sport")
    }
}
