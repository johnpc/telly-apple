import Testing
@testable import Telly

/// Unit coverage for per-channel EPG time-offset math.
struct EpgOffsetsTests {

    private func program(_ channel: String, _ start: Int, _ end: Int) -> ProgramEntity {
        ProgramEntity(channelTvgId: channel, startMs: start, endMs: end,
                      details: ProgramDetails(title: "p"))
    }

    @Test func ofMinutesConvertsAndKeepsFirstPerTvgId() {
        let map = EpgOffsets.ofMinutes([
            TvgOffset(tvgId: "a", epgOffsetMinutes: 2),
            TvgOffset(tvgId: "a", epgOffsetMinutes: 99),   // ignored, first wins
            TvgOffset(tvgId: nil, epgOffsetMinutes: 5),    // skipped
        ])
        #expect(map == ["a": 120_000])
    }

    @Test func queryBoundsPadForMaxForwardAndMinBackwardShift() {
        let offsets = ["a": 120_000, "b": -60_000]
        #expect(EpgOffsets.queryFrom(1_000_000, offsets: offsets) == 1_000_000 - 120_000)
        #expect(EpgOffsets.queryTo(2_000_000, offsets: offsets) == 2_000_000 + 60_000)
    }

    @Test func queryBoundsIgnoreWrongSignAndEmpty() {
        #expect(EpgOffsets.queryFrom(100, offsets: ["a": -5]) == 100)   // no forward shift
        #expect(EpgOffsets.queryTo(100, offsets: ["a": 5]) == 100)      // no backward shift
        #expect(EpgOffsets.queryFrom(100, offsets: [:]) == 100)
    }

    @Test func shiftedMovesOnlyOffsetChannels() {
        let programs = [program("a", 0, 100), program("b", 0, 100)]
        let shifted = EpgOffsets.shifted(programs, offsets: ["a": 50])
        #expect(shifted[0].startMs == 50 && shifted[0].endMs == 150)
        #expect(shifted[1].startMs == 0)                 // b unshifted
        #expect(EpgOffsets.shifted(programs, offsets: [:]) == programs)
    }

    @Test func windowedShiftsThenTrimsToWindow() {
        let programs = [program("a", 0, 100), program("a", 100, 200)]
        let windowed = EpgOffsets.windowed(programs, offsets: ["a": 50], fromMs: 160, toMs: 300)
        #expect(windowed.map(\.startMs) == [150])        // first shifts to 50..150, trimmed out
    }
}
