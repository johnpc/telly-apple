import Testing
@testable import Telly

/// Unit coverage for `ChannelEntity.catchupAttributes()` resolution edges.
struct CatchupAttributesTests {

    private func channel(type: String? = nil, source: String? = nil,
                         days: Int? = nil) -> ChannelEntity {
        var row = ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                                source: ChannelSource(name: "N", streamUrl: "u"))
        row.catchup = ChannelCatchup(catchupType: type, catchupSource: source, catchupDays: days)
        return row
    }

    @Test func bareSourceImpliesDefault() {
        let attrs = channel(source: "http://a?utc=${start}").catchupAttributes()
        #expect(attrs == CatchupAttributes(type: .default, source: "http://a?utc=${start}", days: 7))
    }

    @Test func explicitTypeWinsOverImpliedDefault() {
        #expect(channel(type: "shift", source: "http://a").catchupAttributes()?.type == .shift)
    }

    @Test func templateTypeWithoutSourceIsNil() {
        // .default / .append do not rewrite the live URL, so they need a source.
        #expect(channel(type: "default").catchupAttributes() == nil)
        #expect(channel(type: "append").catchupAttributes() == nil)
    }

    @Test func rewritingTypeNeedsNoSource() {
        let attrs = channel(type: "flussonic").catchupAttributes()
        #expect(attrs == CatchupAttributes(type: .flussonic, source: nil, days: 7))
    }

    @Test func noCapabilityIsNil() {
        #expect(channel().catchupAttributes() == nil)
        #expect(channel(source: "   ").catchupAttributes() == nil)   // blank source ignored
    }

    @Test func daysFallBackToDefaultElseUseGiven() {
        #expect(channel(source: "http://a").catchupAttributes()?.days == 7)
        #expect(channel(source: "http://a", days: 14).catchupAttributes()?.days == 14)
        #expect(CatchupAttributes.defaultDays == 7)
    }
}
