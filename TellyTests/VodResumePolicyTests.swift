import Testing
@testable import Telly

/// Band boundaries for the resume decision (5%–95% permille) plus the
/// unknown-duration guard, ported 1:1 from Android.
struct VodResumePolicyTests {
    @Test func offerResumeAtBandBoundaries() {
        // 49 permille < 50 => below band; 50 => in band; 950 => in band;
        // 951 => above band (finished, not offered).
        #expect(!VodResumePolicy.offerResume(positionMs: 49, durationMs: 1000))
        #expect(VodResumePolicy.offerResume(positionMs: 50, durationMs: 1000))
        #expect(VodResumePolicy.offerResume(positionMs: 950, durationMs: 1000))
        #expect(!VodResumePolicy.offerResume(positionMs: 951, durationMs: 1000))
    }

    @Test func finishedAboveMaxBand() {
        #expect(!VodResumePolicy.finished(positionMs: 950, durationMs: 1000))
        #expect(VodResumePolicy.finished(positionMs: 951, durationMs: 1000))
        #expect(VodResumePolicy.finished(positionMs: 1000, durationMs: 1000))
    }

    @Test func unknownDurationNeverResumesOrFinishes() {
        #expect(!VodResumePolicy.offerResume(positionMs: 500, durationMs: 0))
        #expect(!VodResumePolicy.finished(positionMs: 500, durationMs: 0))
        #expect(!VodResumePolicy.offerResume(positionMs: 500, durationMs: -1))
    }
}
