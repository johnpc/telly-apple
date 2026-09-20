#if os(iOS)
import Testing
@testable import Telly

/// The pure PiP transport arithmetic the VLCKit-4 media controller forwards to:
/// only `.playing` reads as playing, and a relative seek clamps into the valid
/// range (lower bound only for live/unknown-length streams).
struct PipMediaStateTests {
    @Test func onlyPlayingReadsAsPlaying() {
        #expect(PipMediaState.isPlaying(.playing))
        #expect(!PipMediaState.isPlaying(.buffering))
        #expect(!PipMediaState.isPlaying(.reconnecting))
        #expect(!PipMediaState.isPlaying(.ended))
        #expect(!PipMediaState.isPlaying(.idle))
    }

    @Test func seekAddsOffsetWithinFiniteStream() {
        #expect(PipMediaState.seekTarget(positionMs: 10_000, durationMs: 60_000, offsetMs: 5_000) == 15_000)
        #expect(PipMediaState.seekTarget(positionMs: 10_000, durationMs: 60_000, offsetMs: -5_000) == 5_000)
    }

    @Test func seekClampsToBounds() {
        #expect(PipMediaState.seekTarget(positionMs: 1_000, durationMs: 60_000, offsetMs: -5_000) == 0)
        #expect(PipMediaState.seekTarget(positionMs: 59_000, durationMs: 60_000, offsetMs: 5_000) == 60_000)
    }

    @Test func liveStreamClampsLowerBoundOnly() {
        #expect(PipMediaState.seekTarget(positionMs: 1_000, durationMs: 0, offsetMs: 5_000) == 6_000)
        #expect(PipMediaState.seekTarget(positionMs: 1_000, durationMs: 0, offsetMs: -5_000) == 0)
    }
}
#endif
