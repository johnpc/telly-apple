import Testing
@testable import Telly

/// The pure copy-channels helpers: ``CopyChannelsPlan/selectableChannels(_:)``
/// drops HIDDEN channels (Android parity) preserving order;
/// ``CopyChannelsPlan/keys(of:in:)`` maps the checked channel ids to their
/// membership keys via ``ChannelImporter/keyOf(_:)`` in list order; and
/// ``CopyChannelsPlan/defaultTarget(_:)`` returns the sole group only when
/// exactly one exists (Android's `singleOrNull()`).
struct CopyChannelsPlanTests {
    private func channel(id: Int, name: String, hidden: Bool = false) -> ChannelEntity {
        var c = ChannelEntity(playlistId: 1, number: id, sortIndex: id,
                              source: ChannelSource(name: name, groupTitle: nil, logoUrl: nil,
                                                    streamUrl: "http://127.0.0.1/\(name)", tvgId: name))
        c.id = id
        c.flags.hidden = hidden
        return c
    }

    @Test func selectableChannelsDropsHidden() {
        let all = [channel(id: 1, name: "A"), channel(id: 2, name: "B", hidden: true),
                   channel(id: 3, name: "C")]
        #expect(CopyChannelsPlan.selectableChannels(all).map(\.source.name) == ["A", "C"])
    }

    @Test func keysMapSelectionViaKeyOfInOrder() {
        let channels = [channel(id: 1, name: "A"), channel(id: 2, name: "B"),
                        channel(id: 3, name: "C")]
        #expect(CopyChannelsPlan.keys(of: [3, 1], in: channels) == ["A", "C"])
    }

    @Test func keysEmptyWhenNothingSelected() {
        let channels = [channel(id: 1, name: "A")]
        #expect(CopyChannelsPlan.keys(of: [], in: channels).isEmpty)
    }

    @Test func defaultTargetIsSoleGroup() {
        let only = CustomGroup(id: 7, name: "News")
        #expect(CopyChannelsPlan.defaultTarget([only]) == only)
    }

    @Test func defaultTargetNilForNoneOrMany() {
        #expect(CopyChannelsPlan.defaultTarget([]) == nil)
        #expect(CopyChannelsPlan.defaultTarget(
            [CustomGroup(id: 1, name: "A"), CustomGroup(id: 2, name: "B")]) == nil)
    }
}
