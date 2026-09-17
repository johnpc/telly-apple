import Testing
@testable import Telly

/// Unit coverage for `CatchupType.of` and the `rewritesLiveUrl` truth table.
struct CatchupTypeTests {

    @Test func ofMapsTheFiveLiterals() {
        #expect(CatchupType.of("default") == .default)
        #expect(CatchupType.of("append") == .append)
        #expect(CatchupType.of("shift") == .shift)
        #expect(CatchupType.of("flussonic") == .flussonic)
        #expect(CatchupType.of("xc") == .xc)
    }

    @Test func ofTrimsWhitespaceAndLowercases() {
        #expect(CatchupType.of("  DEFAULT  ") == .default)
        #expect(CatchupType.of("Shift") == .shift)
        #expect(CatchupType.of("\tXC\n") == .xc)
    }

    @Test func ofReturnsNilForAbsentEmptyOrUnknown() {
        #expect(CatchupType.of(nil) == nil)
        #expect(CatchupType.of("") == nil)
        #expect(CatchupType.of("   ") == nil)
        #expect(CatchupType.of("timeshift") == nil)
    }

    @Test func rewritesLiveUrlTruthTable() {
        #expect(CatchupType.default.rewritesLiveUrl == false)
        #expect(CatchupType.append.rewritesLiveUrl == false)
        #expect(CatchupType.shift.rewritesLiveUrl == true)
        #expect(CatchupType.flussonic.rewritesLiveUrl == true)
        #expect(CatchupType.xc.rewritesLiveUrl == true)
    }
}
