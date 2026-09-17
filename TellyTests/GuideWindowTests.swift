import CoreGraphics
import Foundation
import Testing
@testable import Telly

/// Unit coverage for the pure guide-grid windowing maths.
struct GuideWindowTests {

    private let half = GuideGeometry.halfHourMs      // 1_800_000
    private let prefetch = GuideWindowMath.prefetchMs // 10_800_000

    @Test func constantsMatchThePlan() {
        #expect(GuideWindowMath.prefetchMs == 3 * 60 * 60_000)
        #expect(GuideWindowMath.forwardDays == 7)
    }

    @Test func visibleSpanMapsTheViewportEndpoints() {
        let span = GuideWindowMath.visibleSpan(originMs: 1_000_000, scrollX: 0, viewport: 640)
        #expect(span.fromMs == 1_000_000)                 // origin at scrollX 0
        #expect(span.toMs == 1_000_000 + 4 * half)        // 640pt = 4 columns = 2h
    }

    @Test func materializeWidensByPrefetchAndLandsOnGridMarks() {
        let visible = GuideWindowMath.visibleSpan(originMs: 0, scrollX: 0, viewport: 640)
        let span = GuideWindowMath.materializeSpan(originMs: 0, scrollX: 0, viewport: 640)
        #expect(span.fromMs == visible.fromMs - prefetch) // widened, already aligned
        #expect(span.toMs == visible.toMs + prefetch)
        #expect(span.fromMs % half == 0)                  // both edges on the 30-min grid
        #expect(span.toMs % half == 0)
    }

    @Test func materializeFloorsUnalignedEdgesAndStillCoversTheVisibleSpan() {
        let visible = GuideWindowMath.visibleSpan(originMs: 0, scrollX: 0, viewport: 500)
        let span = GuideWindowMath.materializeSpan(originMs: 0, scrollX: 0, viewport: 500)
        #expect(span.fromMs % half == 0)
        #expect(span.toMs % half == 0)
        #expect(span.fromMs <= visible.fromMs)            // covers the on-screen range
        #expect(span.toMs >= visible.toMs)
    }

    @Test func quantizeDownIsIdempotentForwardAndBackward() {
        let origin = 1_000_000
        let forward = GuideWindowMath.quantizeDown(timeMs: origin + 47 * 60_000, originMs: origin)
        #expect(forward == origin + half)                 // 47 min → 30 min mark
        #expect(GuideWindowMath.quantizeDown(timeMs: forward, originMs: origin) == forward)
        let backward = GuideWindowMath.quantizeDown(timeMs: origin - 100, originMs: origin)
        #expect(backward == origin - half)                // floors below the origin
        #expect(GuideWindowMath.quantizeDown(timeMs: backward, originMs: origin) == backward)
    }

    @Test func scrollFloorClampsNonPositivePastDaysToZero() {
        #expect(GuideWindowMath.scrollFloor(pastDays: 0) == 0)
        #expect(GuideWindowMath.scrollFloor(pastDays: -3) == 0)
        #expect(GuideWindowMath.scrollFloor(pastDays: 2)
                == -CGFloat(2 * GuideGeometry.dayMs) * GuideGeometry.pointsPerMs)
    }

    @Test func scrollCeilIsForwardDaysAhead() {
        let ceil = GuideWindowMath.scrollCeil()
        #expect(ceil == GuideGeometry.xOf(GuideWindowMath.forwardDays * GuideGeometry.dayMs, originMs: 0))
        #expect(ceil == 53_760)
    }
}
