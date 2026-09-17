import Testing
@testable import Telly

/// The pure Assign-EPG picker builder + persist mapping (Android
/// `AssignEpgSession.uiOf` + its `channel.copy(overrides:)` write): the "Auto
/// (tvg-id)" row is always first, each EPG id follows, `selected` tracks the
/// channel's current override, and `applied` both sets and clears it.
struct AssignEpgOptionsTests {
    private func channel(tvgId: String? = "auto", override: String? = nil) -> ChannelEntity {
        var row = ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                                source: ChannelSource(name: "N", streamUrl: "u", tvgId: tvgId))
        row.overrides.epgOverride = override
        return row
    }

    @Test func autoRowFirstAndSelectedWhenNoOverride() {
        let rows = AssignEpgOptions.rows(channel: channel(), epgIds: ["bbc", "cnn"])
        #expect(rows.map(\.id) == [nil, "bbc", "cnn"])
        #expect(rows[0].title == "Auto (tvg-id)")
        #expect(rows[0].summary == "auto")            // summary = the channel's tvg-id
        #expect(rows[0].selected == true)             // Auto selected with no override
        #expect(rows.dropFirst().allSatisfy { !$0.selected })
    }

    @Test func concreteIdSelectedWhenItMatchesOverride() {
        let rows = AssignEpgOptions.rows(channel: channel(override: "cnn"), epgIds: ["bbc", "cnn"])
        #expect(rows[0].selected == false)            // Auto no longer selected
        #expect(rows.first { $0.id == "cnn" }?.selected == true)
        #expect(rows.first { $0.id == "bbc" }?.selected == false)
    }

    @Test func emptyEpgIdsYieldsAutoRowOnly() {
        let rows = AssignEpgOptions.rows(channel: channel(), epgIds: [])
        #expect(rows.count == 1)
        #expect(rows[0].id == nil)
    }

    @Test func appliedSetsThenClearsOverride() {
        let base = channel()
        let set = AssignEpgOptions.applied(base, override: "cnn")
        #expect(set.overrides.epgOverride == "cnn")
        #expect(set.epgId == "cnn")                   // resolved id follows the override
        let cleared = AssignEpgOptions.applied(set, override: nil)
        #expect(cleared.overrides.epgOverride == nil)
        #expect(cleared.epgId == "auto")              // back to Auto (tvg-id)
    }
}
