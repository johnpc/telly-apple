import Testing
@testable import Telly

/// The pure custom-group surfacing: names preserve `sortIndex` (store) order,
/// membership resolves by refresh-stable key preserving channel order (dropping
/// non-members), and an unknown group name resolves to nil.
struct CustomGroupChannelsTests {
    private func ch(_ id: Int, tvg: String) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts", tvgId: tvg))
    }

    private func key(_ tvg: String) -> String {
        ChannelImporter.identityOf(tvgId: tvg, streamUrl: "unused", name: "unused")
    }

    @Test func namesPreserveStoreOrder() {
        let customs = [CustomGroup(id: 3, name: "Kids"), CustomGroup(id: 1, name: "Sports")]
        #expect(CustomGroupChannels.names(customs) == ["Kids", "Sports"])
    }

    @Test func channelsFilterByKeyPreservingOrderDroppingNonMembers() {
        let all = [ch(1, tvg: "a"), ch(2, tvg: "b"), ch(3, tvg: "c")]
        let members: Set<String> = [key("c"), key("a")]
        #expect(CustomGroupChannels.channels(all, memberKeys: members).map(\.id) == [1, 3])
    }

    @Test func channelsEmptyWhenNoMembersMatch() {
        let all = [ch(1, tvg: "a"), ch(2, tvg: "b")]
        #expect(CustomGroupChannels.channels(all, memberKeys: [key("z")]).isEmpty)
    }

    @Test func membersFoundByName() {
        let customs = [CustomGroup(id: 1, name: "Kids", members: [key("a"), key("b")])]
        #expect(CustomGroupChannels.members(named: "Kids", in: customs) == [key("a"), key("b")])
    }

    @Test func membersNilForUnknownName() {
        let customs = [CustomGroup(id: 1, name: "Kids")]
        #expect(CustomGroupChannels.members(named: "Nope", in: customs) == nil)
    }
}
