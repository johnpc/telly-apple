import Testing
import Foundation
@testable import Telly

/// The pure catch-up badge label: title + wall-clock range, 12h/24h, and the
/// title-less fallback. Times are evaluated in UTC for determinism.
struct CatchupBadgeTests {
    private let utc = TimeZone(identifier: "UTC")!
    // 14:05 → 15:35 UTC.
    private let start = 50_700_000
    private let end = 56_100_000

    private func badge(title: String?) -> CatchupBadge {
        CatchupBadge(title: title, startMs: start, endMs: end)
    }

    @Test func labelWithTitleIn24hJoinsTitleAndRange() {
        #expect(badge(title: "The News").label(is24h: true, timeZone: utc)
            == "The News · 14:05–15:35")
    }

    @Test func labelWithTitleIn12hUsesAmPmRange() {
        #expect(badge(title: "The News").label(is24h: false, timeZone: utc)
            == "The News · 2:05 PM–3:35 PM")
    }

    @Test func labelWithoutTitleIsRangeOnly() {
        #expect(badge(title: nil).label(is24h: true, timeZone: utc) == "14:05–15:35")
    }

    @Test func labelWithEmptyTitleIsRangeOnly() {
        #expect(badge(title: "").label(is24h: true, timeZone: utc) == "14:05–15:35")
    }
}
