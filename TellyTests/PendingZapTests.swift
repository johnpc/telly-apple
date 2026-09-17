import Testing
@testable import Telly

/// Trailing-debounce coalescing of rapid channel-zap presses.
struct PendingZapTests {
    @Test func singlePressResolvesAfterSettle() {
        var pending = PendingZap(settleMs: 250)
        pending.press(delta: 1, at: 0)
        #expect(pending.resolve(at: 249) == nil)
        #expect(pending.resolve(at: 250) == 1)
    }

    @Test func rapidPressesCoalesce() {
        var pending = PendingZap(settleMs: 250)
        pending.press(delta: 1, at: 0)
        pending.press(delta: 1, at: 100)
        pending.press(delta: 1, at: 200)
        #expect(pending.resolve(at: 300) == nil)
        #expect(pending.resolve(at: 450) == 3)
        #expect(pending.resolve(at: 1_000) == nil)
    }

    @Test func oppositePressesNetToZero() {
        var pending = PendingZap(settleMs: 250)
        pending.press(delta: 1, at: 0)
        pending.press(delta: -1, at: 50)
        #expect(pending.resolve(at: 300) == 0)
    }

    @Test func resolveBeforeAnyPressIsNil() {
        var pending = PendingZap(settleMs: 250)
        #expect(pending.resolve(at: 1_000) == nil)
    }

    @Test func resolveYieldsOnceThenClears() {
        var pending = PendingZap(settleMs: 250)
        pending.press(delta: 2, at: 0)
        #expect(pending.resolve(at: 250) == 2)
        #expect(pending.resolve(at: 250) == nil)
    }

    @Test func holdReArmsDeadline() {
        var pending = PendingZap(settleMs: 250)
        pending.press(delta: 1, at: 0)
        pending.press(delta: 1, at: 100)
        pending.press(delta: 1, at: 200)
        pending.press(delta: 1, at: 300)
        #expect(pending.resolve(at: 250) == nil)
        #expect(pending.resolve(at: 550) == 4)
    }
}
