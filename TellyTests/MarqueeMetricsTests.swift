import CoreGraphics
import Foundation
import Testing
@testable import Telly

/// Unit coverage for the pure ping-pong marquee timing.
struct MarqueeMetricsTests {

    @Test func nonOverflowingTextNeverScrolls() {
        #expect(!MarqueeMetrics.overflows(textWidth: 90, containerWidth: 100))
        #expect(MarqueeMetrics.offset(textWidth: 90, containerWidth: 100, elapsed: 5) == 0)
    }

    @Test func subPointSliverCountsAsFitting() {
        #expect(abs(MarqueeMetrics.overflow(textWidth: 100.3, containerWidth: 100) - 0.3) < 0.001)
        #expect(!MarqueeMetrics.overflows(textWidth: 100.3, containerWidth: 100))
    }

    @Test func overflowIsTheHiddenTail() {
        #expect(MarqueeMetrics.overflow(textWidth: 260, containerWidth: 200) == 60)
        #expect(MarqueeMetrics.overflows(textWidth: 260, containerWidth: 200))
    }

    @Test func restsAlignedDuringTheOpeningPause() {
        #expect(MarqueeMetrics.offset(textWidth: 260, containerWidth: 200, elapsed: 0) == 0)
        #expect(MarqueeMetrics.offset(textWidth: 260, containerWidth: 200,
                                      elapsed: MarqueeMetrics.endPause - 0.01) == 0)
    }

    @Test func slidesFullyLeftByTheEndOfTheOutboundLeg() {
        let over: CGFloat = 60
        let travel = Double(over) / Double(MarqueeMetrics.speed)
        let atFarEnd = MarqueeMetrics.endPause + travel
        #expect(abs(MarqueeMetrics.offset(textWidth: 260, containerWidth: 200,
                                          elapsed: atFarEnd) + over) < 0.001)
    }

    @Test func holdsAtTheFarEndThenReturns() {
        let over: CGFloat = 60
        let travel = Double(over) / Double(MarqueeMetrics.speed)
        // Midway through the end pause: still fully left.
        let midEndPause = MarqueeMetrics.endPause + travel + MarqueeMetrics.endPause / 2
        #expect(abs(MarqueeMetrics.offset(textWidth: 260, containerWidth: 200,
                                          elapsed: midEndPause) + over) < 0.001)
        // A full cycle later it has looped back to aligned.
        let cycle = MarqueeMetrics.endPause + travel + MarqueeMetrics.endPause + travel
        #expect(abs(MarqueeMetrics.offset(textWidth: 260, containerWidth: 200,
                                          elapsed: cycle)) < 0.001)
    }

    @Test func offsetStaysWithinTheHiddenRange() {
        for step in 0..<40 {
            let o = MarqueeMetrics.offset(textWidth: 260, containerWidth: 200,
                                          elapsed: Double(step) * 0.2)
            #expect(o <= 0.001 && o >= -60.001)
        }
    }
}
