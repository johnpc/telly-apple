import Foundation
import Testing
@testable import Telly

/// The pure search air-time label: bare "HH:mm — HH:mm" (em dash) range for a
/// programme on `atMs`'s day, "EEE, MMM d, " prefix on any other day. UTC keeps
/// the day boundary and labels deterministic; month names stay en-US via the
/// formatter's `en_US_POSIX` locale, so structure assertions are stable.
struct SearchAirTimeTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func prog(_ startMs: Int, _ endMs: Int) -> ProgramEntity {
        ProgramEntity(channelTvgId: "a", startMs: startMs, endMs: endMs,
                      details: ProgramDetails(title: "Show"))
    }

    @Test func sameDayIsBareRangeWithEmDash() {
        // 1970-01-01 in UTC: 03:00 — 04:00. atMs shares the day.
        let text = SearchAirTime.text(program: prog(10_800_000, 14_400_000), atMs: 3_600_000, timeZone: utc)
        #expect(text == "03:00 — 04:00")
        #expect(text.contains(" — ")) // em dash U+2014, matching Android ProgramTimes.range
        #expect(!text.contains(","))  // no date prefix on the same day
    }

    @Test func otherDayCarriesDatePrefix() {
        // start on day 2 (1970-01-02 00:30 UTC), atMs on day 1 → prefixed.
        let start = 86_400_000 + 1_800_000
        let text = SearchAirTime.text(program: prog(start, start + 3_600_000), atMs: 0, timeZone: utc)
        #expect(text.contains(", "))          // "EEE, MMM d, " prefix present
        #expect(text.hasSuffix("00:30 — 01:30"))
        #expect(text.hasPrefix("Fri, Jan 2")) // 1970-01-02 is a Friday in en-US
    }

    @Test func stampIsSingleInstantWithDatePrefix() {
        // 1970-01-02 00:30 UTC → weekday + date + single time, no range dash.
        let start = 86_400_000 + 1_800_000
        let text = SearchAirTime.stamp(atMs: start, timeZone: utc)
        #expect(text == "Fri, Jan 2, 00:30")
        #expect(!text.contains(" — ")) // single instant, not a range
    }
}
