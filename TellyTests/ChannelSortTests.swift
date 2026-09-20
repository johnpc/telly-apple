import Testing
@testable import Telly

/// The pure channel-sort ordering: default passthrough, Name A–Z with a stable
/// (default-order) tie-break, edge sizes, and raw-value coercion.
struct ChannelSortTests {
    private func ch(_ id: Int, _ name: String) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: name, groupTitle: nil,
                                            streamUrl: "http://x/\(id)"))
    }

    @Test func defaultPreservesIncomingOrder() {
        let list = [ch(1, "Zeta"), ch(2, "Alpha"), ch(3, "Mid")]
        #expect(ChannelSort.default.sorted(list).map(\.id) == [1, 2, 3])
    }

    @Test func nameAZOrdersCaseInsensitively() {
        let list = [ch(1, "Zeta"), ch(2, "alpha"), ch(3, "Mid")]
        #expect(ChannelSort.nameAZ.sorted(list).map(\.source.name) == ["alpha", "Mid", "Zeta"])
    }

    @Test func nameAZBreaksTiesByDefaultOrder() {
        // Three equally-named channels keep their original relative order.
        let list = [ch(3, "News"), ch(1, "News"), ch(2, "News")]
        #expect(ChannelSort.nameAZ.sorted(list).map(\.id) == [3, 1, 2])
    }

    @Test func nameAZUsesDisplayNameOverride() {
        var overridden = ch(1, "Zeta")
        overridden.overrides = ChannelOverrides(customName: "Aaa")
        let list = [overridden, ch(2, "Bbb")]
        #expect(ChannelSort.nameAZ.sorted(list).map(\.id) == [1, 2])
    }

    @Test func handlesEmptyAndSingleItem() {
        #expect(ChannelSort.nameAZ.sorted([]).isEmpty)
        #expect(ChannelSort.default.sorted([]).isEmpty)
        #expect(ChannelSort.nameAZ.sorted([ch(9, "Solo")]).map(\.id) == [9])
    }

    @Test func fromCoercesUnknownRawToDefault() {
        #expect(ChannelSort.from(0) == .default)
        #expect(ChannelSort.from(1) == .nameAZ)
        #expect(ChannelSort.from(9_999) == .default)
        #expect(ChannelSort.from(-1) == .default)
    }

    @Test func titlesAreDistinct() {
        #expect(ChannelSort.default.title == "Default")
        #expect(ChannelSort.nameAZ.title != ChannelSort.default.title)
    }

    @Test func casesAreIdentifiableByRawValue() {
        #expect(ChannelSort.allCases.map(\.id) == ChannelSort.allCases.map(\.rawValue))
        #expect(ChannelSort.allCases.count == 2)
    }
}
