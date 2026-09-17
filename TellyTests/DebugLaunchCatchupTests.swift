#if DEBUG
import Testing
@testable import Telly

/// The DEBUG catch-up screenshot harness's pure seeding logic: launch-arg
/// parsing, the fixture channel's catch-up template, the already-aired programme,
/// and that the pair resolves a playable archive URL through the shipped core.
struct DebugLaunchCatchupTests {
    private static let realisticNow = 1_700_000_000_000

    @Test func catchupDemoRequestedReadsFlag() {
        #expect(DebugLaunch.catchupDemoRequested(in: ["Telly", "-tellyCatchup"]))
        #expect(!DebugLaunch.catchupDemoRequested(in: ["Telly"]))
        #expect(!DebugLaunch.catchupDemoRequested(in: ["Telly", "-tellyGuide"]))
    }

    @Test func fixturePlaylistChannelCarriesCatchupTemplate() {
        let pl = DebugLaunch.catchupFixturePlaylist(base: "http://127.0.0.1:8000/")
        #expect(pl.epgURL == nil)
        #expect(pl.channels.count == 1)
        let channel = pl.channels[0]
        #expect(channel.catchup == "default")
        #expect(channel.catchupDays == 7)
        #expect(channel.tvgID == DebugLaunch.demoEpgId)
        #expect(channel.streamURL == "http://127.0.0.1:8000/live.ts")
        #expect(channel.catchupSource == "http://127.0.0.1:8000/archive?utc=${start}&dur=${duration}")
    }

    @Test func catchupEpgDocumentProducesAnAiredProgramme() {
        let doc = DebugLaunch.catchupEpgDocument(nowMs: Self.realisticNow)
        #expect(doc.programs.count == 1)
        let program = doc.programs[0]
        #expect(program.channelId == DebugLaunch.demoEpgId)
        #expect(program.endMs < Self.realisticNow)                 // fully aired
        #expect(program.startMs == Self.realisticNow - 90 * 60_000)
        #expect(program.endMs == Self.realisticNow - 30 * 60_000)
    }

    // The fixture channel + aired window resolves the fake local archive URL the
    // proof plays — proving the template + builder combine as expected.
    @Test func fixtureResolvesTheArchiveUrl() {
        let channel = DebugLaunch.catchupFixturePlaylist(base: "http://127.0.0.1:8000/").channels[0]
        let attributes = CatchupAttributes(type: .default, source: channel.catchupSource,
                                           days: channel.catchupDays ?? 7)
        let start = Self.realisticNow - 90 * 60_000, end = Self.realisticNow - 30 * 60_000
        let url = CatchupUrlBuilder.build(streamUrl: channel.streamURL, attributes: attributes,
                                          startMs: start, endMs: end, nowMs: Self.realisticNow)
        #expect(url == "http://127.0.0.1:8000/archive?utc=\(start / 1_000)&dur=\((end - start) / 1_000)")
    }
}
#endif
