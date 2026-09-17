import Testing
@testable import Telly

/// Unit coverage for `XtreamUrl.build`: the UTC timestamp string, minute
/// round-UP, and nil on any non-Xtream URL shape.
struct XtreamUrlTests {

    // 2021-01-01T00:00:00 UTC = 1_609_459_200_000 ms.
    private let startMs = 1_609_459_200_000

    @Test func buildsTimeshiftEndpointWithUtcStampAndRoundedMinutes() {
        // 61s span rounds UP to 2 whole minutes.
        let out = XtreamUrl.build(streamUrl: "http://host:8080/live/user/pass/12345.ts",
                                  startMs: startMs, endMs: startMs + 61_000)
        #expect(out == "http://host:8080/timeshift/user/pass/2/2021-01-01:00-00/12345.ts")
    }

    @Test func matchesShapeWithoutLiveSegmentOrExtension() {
        let out = XtreamUrl.build(streamUrl: "https://host/user/pass/9",
                                  startMs: startMs, endMs: startMs + 60_000)
        #expect(out == "https://host/timeshift/user/pass/1/2021-01-01:00-00/9.ts")
    }

    @Test func returnsNilForNonXtreamUrls() {
        #expect(XtreamUrl.build(streamUrl: "http://host/playlist.m3u8",
                                startMs: startMs, endMs: startMs + 60_000) == nil)
        #expect(XtreamUrl.build(streamUrl: "not a url",
                                startMs: startMs, endMs: startMs + 60_000) == nil)
    }
}
