import Testing
@testable import Telly

/// Unit coverage for the pure EPG refresh/staleness policy.
struct RefreshSchedulerTests {

    @Test func neverFetchedIsDue() {
        #expect(RefreshScheduler.isDue(lastUpdatedMs: 0, nowMs: 1_000))
        #expect(RefreshScheduler.isDue(lastUpdatedMs: -1, nowMs: 1_000))
    }

    @Test func withinIntervalIsNotDue() {
        let now = 10 * RefreshScheduler.dayMs
        #expect(!RefreshScheduler.isDue(lastUpdatedMs: now - 1, nowMs: now))
    }

    @Test func agedPastIntervalIsDue() {
        let now = 10 * RefreshScheduler.dayMs
        #expect(RefreshScheduler.isDue(lastUpdatedMs: now - RefreshScheduler.defaultIntervalMs, nowMs: now))
    }

    @Test func zeroIntervalMakesOnlyNeverFetchedDue() {
        let now = 10 * RefreshScheduler.dayMs
        #expect(RefreshScheduler.isDue(lastUpdatedMs: 0, nowMs: now, intervalMs: 0))
        #expect(!RefreshScheduler.isDue(lastUpdatedMs: 1, nowMs: now, intervalMs: 0))
    }

    @Test func hoursToMsConverts() {
        #expect(RefreshScheduler.hoursToMs(0) == 0)
        #expect(RefreshScheduler.hoursToMs(-3) == 0)
        #expect(RefreshScheduler.hoursToMs(2) == 2 * RefreshScheduler.hourMs)
    }

    @Test func daysToMsClampsNegatives() {
        #expect(RefreshScheduler.daysToMs(-1) == 0)
        #expect(RefreshScheduler.daysToMs(7) == 7 * RefreshScheduler.dayMs)
    }

    @Test func constantsMatchDocumentedValues() {
        #expect(RefreshScheduler.hourMs == 3_600_000)
        #expect(RefreshScheduler.dayMs == 86_400_000)
        #expect(RefreshScheduler.defaultIntervalMs == 86_400_000)
        #expect(RefreshScheduler.defaultKeepPastMs == 7 * 86_400_000)
    }
}
