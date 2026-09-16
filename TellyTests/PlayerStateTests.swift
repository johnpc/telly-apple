import Testing
@testable import Telly

/// `PlayerState` equality — documents intent and keeps the enum referenced.
struct PlayerStateTests {
    @Test func errorEqualityComparesTheMessage() {
        #expect(PlayerState.error("x") == PlayerState.error("x"))
        #expect(PlayerState.error("x") != PlayerState.error("y"))
    }

    @Test func distinctCasesAreNotEqual() {
        #expect(PlayerState.playing != PlayerState.buffering)
        #expect(PlayerState.idle != PlayerState.ended)
        #expect(PlayerState.reconnecting != PlayerState.playing)
    }
}
