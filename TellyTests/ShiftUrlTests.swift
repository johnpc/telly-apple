import Testing
@testable import Telly

/// Unit coverage for `ShiftUrl.build`: `utc`/`lutc` in epoch seconds, joined
/// with `&` when the URL already has a query, else `?`.
struct ShiftUrlTests {

    @Test func appendsWithQuestionMarkWhenNoQuery() {
        let out = ShiftUrl.build(streamUrl: "http://a/stream", startMs: 10_000, nowMs: 50_000)
        #expect(out == "http://a/stream?utc=10&lutc=50")
    }

    @Test func appendsWithAmpersandWhenQueryPresent() {
        let out = ShiftUrl.build(streamUrl: "http://a/stream?x=1", startMs: 10_000, nowMs: 50_000)
        #expect(out == "http://a/stream?x=1&utc=10&lutc=50")
    }
}
