import Testing
@testable import Telly

/// The pure group-list derivation: distinct non-empty group titles in
/// first-appearance order, with blank/absent groups dropped and each name once.
struct ChannelGroupsTests {
    private func channel(_ name: String, group: String?) -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: name, groupTitle: group,
                                            logoUrl: nil, streamUrl: "http://x/\(name)", tvgId: name))
    }

    @Test func emptyChannelsYieldNoGroups() {
        #expect(ChannelGroups.names([]).isEmpty)
    }

    @Test func keepsFirstAppearanceOrderAndDeduplicates() {
        let channels = [channel("A", group: "News"), channel("B", group: "Movies"),
                        channel("C", group: "News")]
        #expect(ChannelGroups.names(channels) == ["News", "Movies"])
    }

    @Test func dropsNilAndBlankGroups() {
        let channels = [channel("A", group: nil), channel("B", group: ""),
                        channel("C", group: "Sport")]
        #expect(ChannelGroups.names(channels) == ["Sport"])
    }
}
