import Testing
@testable import Telly

/// Unit coverage for `FlussonicUrl.build`: all three last-segment rewrite
/// branches, epoch seconds, and query-string preservation. start=10s, dur=30s.
struct FlussonicUrlTests {

    private func build(_ url: String) -> String {
        FlussonicUrl.build(streamUrl: url, startMs: 10_000, endMs: 40_000)
    }

    @Test func mpegtsBecomesArchiveTsPreservingQuery() {
        #expect(build("http://h/live/mpegts?token=1") == "http://h/live/archive-10-30.ts?token=1")
    }

    @Test func videoM3u8KeepsVideoPrefix() {
        #expect(build("http://h/live/video.m3u8") == "http://h/live/video-10-30.m3u8")
    }

    @Test func otherLastSegmentBecomesArchiveM3u8PreservingQuery() {
        #expect(build("http://h/live/mono.m3u8?a=b") == "http://h/live/archive-10-30.m3u8?a=b")
    }
}
