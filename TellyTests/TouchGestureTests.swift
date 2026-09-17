import CoreGraphics
import Testing
@testable import Telly

/// Table-drives ``TouchGesture/swipe(dx:dy:)`` — dominant-axis + sign
/// classification, the near-zero → `.tap` path, tie-breaks to horizontal, and
/// the SwiftUI sign convention (positive `dy` is downward, so negative `dy` is an
/// upward swipe).
struct TouchGestureTests {
    struct Case: Sendable {
        let dx: CGFloat
        let dy: CGFloat
        let expected: TouchGesture
    }

    @Test(arguments: [
        Case(dx: 0, dy: 0, expected: .tap),          // dead centre
        Case(dx: 12, dy: -10, expected: .tap),       // both below threshold
        Case(dx: 0, dy: -40, expected: .swipeUp),    // negative dy = upward
        Case(dx: 0, dy: 40, expected: .swipeDown),
        Case(dx: -40, dy: 0, expected: .swipeLeft),
        Case(dx: 40, dy: 0, expected: .swipeRight),
        Case(dx: 60, dy: -30, expected: .swipeRight), // horizontal dominant
        Case(dx: 30, dy: -60, expected: .swipeUp),    // vertical dominant
        Case(dx: -20, dy: 55, expected: .swipeDown),
        Case(dx: 40, dy: 40, expected: .swipeRight),  // exact tie → horizontal (+)
        Case(dx: -40, dy: -40, expected: .swipeLeft), // exact tie → horizontal (-)
        Case(dx: -50, dy: 25, expected: .swipeLeft),
    ])
    func classify(_ c: Case) {
        #expect(TouchGesture.swipe(dx: c.dx, dy: c.dy) == c.expected)
    }
}
