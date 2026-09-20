import Testing
@testable import Telly

/// The pure key→action map + selection clamp shared by the pane menu and the
/// channel picker: UP/DOWN move, OK activates, MENU/BACK close, all else inert;
/// motion clamps into range. Exercised without a view.
struct MultiviewMenuPolicyTests {
    @Test func upDownMoveByOneStep() {
        #expect(MultiviewMenuPolicy.action(for: .up) == .move(-1))
        #expect(MultiviewMenuPolicy.action(for: .down) == .move(1))
    }

    @Test func okActivatesAndBackMenuClose() {
        #expect(MultiviewMenuPolicy.action(for: .ok) == .activate)
        #expect(MultiviewMenuPolicy.action(for: .back) == .close)
        #expect(MultiviewMenuPolicy.action(for: .menu) == .close)
    }

    @Test func lateralAndMediaKeysAreInert() {
        #expect(MultiviewMenuPolicy.action(for: .left) == .ignored)
        #expect(MultiviewMenuPolicy.action(for: .channelUp) == .ignored)
    }

    @Test func movedClampsIntoRange() {
        #expect(MultiviewMenuPolicy.moved(selection: 0, by: -1, count: 3) == 0)
        #expect(MultiviewMenuPolicy.moved(selection: 2, by: 1, count: 3) == 2)
        #expect(MultiviewMenuPolicy.moved(selection: 1, by: 1, count: 3) == 2)
    }

    @Test func movedOnEmptyListStaysAtZero() {
        #expect(MultiviewMenuPolicy.moved(selection: 0, by: 1, count: 0) == 0)
    }
}
