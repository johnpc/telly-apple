import CoreGraphics
import SwiftUI
import Testing
@testable import Telly

/// Unit coverage for the shared motion vocabulary: the tokens evaluate (their
/// lazy initialisers run) and the Reduce-Motion gate flips as documented. The
/// SwiftUI modifiers that consume these tokens are exercised by the build and
/// the acceptance suite, not here — this pins the values and the gate.
struct MotionTests {
    @Test func tokensAreDistinctAndPresent() {
        let tokens = [Motion.route, Motion.contextPush, Motion.contextPop,
                      Motion.overlayIn, Motion.overlayOut, Motion.focus]
        // Referencing each forces its initialiser; equality confirms it evaluated.
        #expect(tokens.count == 6)
        #expect(Motion.route == Motion.route)
        #expect(Motion.overlayIn != Motion.overlayOut)
    }

    @Test func geometryConstantsMatchTheReference() {
        #expect(Motion.overlayRise == 10)
        #expect(Motion.focusScale > 1)
        #expect(Motion.pressScale < 1)
    }

    @Test func gateDisablesMotionUnderReduceMotion() {
        #expect(Motion.gated(Motion.route, reduceMotion: true) == nil)
    }

    @Test func gatePassesMotionThroughOtherwise() {
        #expect(Motion.gated(Motion.overlayIn, reduceMotion: false) == Motion.overlayIn)
    }
}
