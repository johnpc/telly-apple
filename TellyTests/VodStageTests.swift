import Testing
@testable import Telly

/// The `VodProgress` permille math (clamped [0, 1000], zero on unknown duration)
/// and the `VodStage` cases the playback model transitions through.
struct VodStageTests {
    @Test func permilleIsClampedProgress() {
        #expect(VodProgress(positionMs: 250, durationMs: 1000).permille == 250)
        #expect(VodProgress(positionMs: 0, durationMs: 1000).permille == 0)
    }

    @Test func unknownDurationIsZeroPermille() {
        #expect(VodProgress(positionMs: 500, durationMs: 0).permille == 0)
        #expect(VodProgress(positionMs: 500, durationMs: -10).permille == 0)
    }

    @Test func permilleClampsAtBothEnds() {
        #expect(VodProgress(positionMs: 5_000, durationMs: 1000).permille == 1000)
        #expect(VodProgress(positionMs: -5_000, durationMs: 1000).permille == 0)
    }

    @Test func stagesAreEquatable() {
        #expect(VodStage.resumePrompt(positionMs: 12) == .resumePrompt(positionMs: 12))
        #expect(VodStage.loading != .playing)
    }
}
