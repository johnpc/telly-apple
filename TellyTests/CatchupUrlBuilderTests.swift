import Testing
@testable import Telly

/// Unit coverage for `CatchupUrlBuilder.build` dispatch per catch-up type,
/// including the nil paths (missing template source / non-Xtream shape).
struct CatchupUrlBuilderTests {

    private let streamUrl = "http://host:8080/live/user/pass/12345.ts"
    private let startMs = 10_000
    private let endMs = 40_000
    private let nowMs = 50_000

    private func build(_ attrs: CatchupAttributes) -> String? {
        CatchupUrlBuilder.build(streamUrl: streamUrl, attributes: attrs,
                                startMs: startMs, endMs: endMs, nowMs: nowMs)
    }

    private func attrs(_ type: CatchupType, source: String? = nil) -> CatchupAttributes {
        CatchupAttributes(type: type, source: source, days: 7)
    }

    @Test func defaultExpandsTheSourceTemplate() {
        #expect(build(attrs(.default, source: "http://a?utc=${start}")) == "http://a?utc=10")
    }

    @Test func defaultWithNoSourceIsNil() {
        #expect(build(attrs(.default)) == nil)
    }

    @Test func appendConcatenatesStreamUrlAndExpandedTemplate() {
        #expect(build(attrs(.append, source: "?utc={utc}")) == streamUrl + "?utc=10")
    }

    @Test func appendWithNoSourceIsNil() {
        #expect(build(attrs(.append)) == nil)
    }

    @Test func shiftDelegatesToShiftUrl() {
        #expect(build(attrs(.shift)) == "\(streamUrl)?utc=10&lutc=50")
    }

    @Test func flussonicDelegatesToFlussonicUrl() {
        // Last segment "12345.ts" is neither mpegts nor video.m3u8 → default .m3u8.
        #expect(build(attrs(.flussonic)) == "http://host:8080/live/user/pass/archive-10-30.m3u8")
    }

    @Test func xcDelegatesToXtreamUrlAndIsNilOnNonXtream() {
        #expect(build(attrs(.xc)) != nil)
        let nonXtream = CatchupUrlBuilder.build(streamUrl: "http://host/playlist.m3u8",
                                                attributes: attrs(.xc),
                                                startMs: startMs, endMs: endMs, nowMs: nowMs)
        #expect(nonXtream == nil)
    }
}
