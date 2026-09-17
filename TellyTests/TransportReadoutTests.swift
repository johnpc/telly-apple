import Testing
@testable import Telly

/// Unit coverage for `TransportReadout` — the read-only progress permille (0 /
/// mid / full / clamp) and the "M:SS" / "H:MM:SS" / negative span formatting.
/// Pure: no clock, no engine.
struct TransportReadoutTests {
    @Test func permilleZeroAtStart() {
        #expect(TransportReadout.permille(position: 0, duration: 60_000) == 0)
    }

    @Test func permilleMidwayIsHalf() {
        #expect(TransportReadout.permille(position: 30_000, duration: 60_000) == 500)
    }

    @Test func permilleFullAtEnd() {
        #expect(TransportReadout.permille(position: 60_000, duration: 60_000) == 1000)
    }

    @Test func permilleClampsBeyondEnds() {
        #expect(TransportReadout.permille(position: 90_000, duration: 60_000) == 1000)
        #expect(TransportReadout.permille(position: -10_000, duration: 60_000) == 0)
    }

    @Test func permilleZeroForDegenerateWindow() {
        #expect(TransportReadout.permille(position: 10_000, duration: 0) == 0)
    }

    @Test func spanFormatsMinutesSeconds() {
        #expect(TransportReadout.span(0) == "0:00")
        #expect(TransportReadout.span(5_000) == "0:05")
        #expect(TransportReadout.span(65_000) == "1:05")
    }

    @Test func spanFormatsHoursWhenOverAnHour() {
        #expect(TransportReadout.span(3_600_000) == "1:00:00")
        #expect(TransportReadout.span(3_725_000) == "1:02:05")
    }

    @Test func spanFloorsNegativeToZero() {
        #expect(TransportReadout.span(-5_000) == "0:00")
    }
}
