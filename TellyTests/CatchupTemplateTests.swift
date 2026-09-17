import Testing
@testable import Telly

/// Unit coverage for the SECURITY-CORE template substitution: whitelist tokens
/// resolve to epoch seconds, `${x}` is fully replaced (no stranded `$`), and
/// unknown tokens pass through verbatim.
struct CatchupTemplateTests {

    // start=10s, now=50s, offset=40s, duration=(40000-10000)/1000=30s.
    private let startMs = 10_000
    private let nowMs = 50_000
    private let endMs = 40_000

    private func expand(_ t: String) -> String {
        CatchupTemplate.expand(t, startMs: startMs, endMs: endMs, nowMs: nowMs)
    }

    @Test func secondsIsIntegerDivisionByThousand() {
        #expect(CatchupTemplate.seconds(0) == 0)
        #expect(CatchupTemplate.seconds(1_999) == 1)   // truncates
        #expect(CatchupTemplate.seconds(60_000) == 60)
    }

    @Test func everyWhitelistTokenResolvesToSeconds() {
        let out = expand("utc={utc} start={start} lutc={lutc} now={now} " +
                         "ts={timestamp} off={offset} dur={duration}")
        #expect(out == "utc=10 start=10 lutc=50 now=50 ts=50 off=40 dur=30")
    }

    @Test func dollarBraceSpellingIsFullyReplacedWithNoStrandedDollar() {
        #expect(expand("a${utc}b") == "a10b")
        #expect(expand("${start}-${duration}") == "10-30")
        #expect(!expand("${now}").contains("$"))
    }

    @Test func unknownTokensPassThroughVerbatim() {
        #expect(expand("x{foo}y{utc}") == "x{foo}y10")
        #expect(expand("${foo}") == "${foo}")
        #expect(expand("no tokens here") == "no tokens here")
    }
}
