import Testing
@testable import Telly

/// The pure 2D multiview focus math: floor-mod edge wrap on a full 2x2 from every
/// corner, partial-grid clamping over empty trailing slots, and the single-cell
/// no-move. Direct-call, exhaustive.
struct MultiviewFocusTests {
    private func moved(_ active: Int, _ dir: MultiviewDirection,
                       count: Int = 4, rows: Int = 2, columns: Int = 2) -> Int {
        MultiviewFocus.moved(active: active, direction: dir,
                             rows: rows, columns: columns, count: count)
    }

    @Test func fullGridWrapsFromTopLeft() {
        #expect(moved(0, .up) == 2)
        #expect(moved(0, .down) == 2)
        #expect(moved(0, .left) == 1)
        #expect(moved(0, .right) == 1)
    }

    @Test func fullGridWrapsFromTopRight() {
        #expect(moved(1, .up) == 3)
        #expect(moved(1, .down) == 3)
        #expect(moved(1, .left) == 0)
        #expect(moved(1, .right) == 0)
    }

    @Test func fullGridWrapsFromBottomLeft() {
        #expect(moved(2, .up) == 0)
        #expect(moved(2, .down) == 0)
        #expect(moved(2, .left) == 3)
        #expect(moved(2, .right) == 3)
    }

    @Test func fullGridWrapsFromBottomRight() {
        #expect(moved(3, .up) == 1)
        #expect(moved(3, .down) == 1)
        #expect(moved(3, .left) == 2)
        #expect(moved(3, .right) == 2)
    }

    @Test func partialGridStepsIntoExistingTile() {
        // 3 tiles in a 2x2: indices 0,1 top row, 2 bottom-left.
        #expect(moved(0, .down, count: 3) == 2)
        #expect(moved(2, .up, count: 3) == 0)
    }

    @Test func partialGridHoldsWhenNowhereValid() {
        // Bottom-right slot is empty; moving toward it (or wrapping to self) holds.
        #expect(moved(1, .down, count: 3) == 1)
        #expect(moved(2, .right, count: 3) == 2)
        #expect(moved(2, .left, count: 3) == 2)
    }

    @Test func singleCellNeverMoves() {
        #expect(moved(0, .up, count: 1, rows: 1, columns: 1) == 0)
        #expect(moved(0, .down, count: 1, rows: 1, columns: 1) == 0)
        #expect(moved(0, .left, count: 1, rows: 1, columns: 1) == 0)
        #expect(moved(0, .right, count: 1, rows: 1, columns: 1) == 0)
    }

    @Test func emptyGridReturnsActive() {
        #expect(moved(0, .up, count: 0, rows: 0, columns: 0) == 0)
    }
}
