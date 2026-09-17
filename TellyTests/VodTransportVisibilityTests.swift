import Testing
@testable import Telly

/// The clock-injected transport auto-hide: a poke reveals it, it hides after the
/// threshold while playing, stays up while paused, and a fresh poke restarts it.
struct VodTransportVisibilityTests {
    @Test func pokeRevealsThenHidesAfterThresholdWhilePlaying() {
        var transport = VodTransportVisibility()
        transport.poke(paused: false, at: 0)
        #expect(transport.resolve(at: 4_999) == true)
        #expect(transport.resolve(at: 5_000) == false)
    }

    @Test func staysVisibleWhilePaused() {
        var transport = VodTransportVisibility()
        transport.poke(paused: true, at: 0)
        #expect(transport.resolve(at: 10_000_000) == true)
    }

    @Test func pokeResetsTheCountdown() {
        var transport = VodTransportVisibility()
        transport.poke(paused: false, at: 0)
        transport.poke(paused: false, at: 4_000)
        #expect(transport.resolve(at: 8_000) == true)
        #expect(transport.resolve(at: 9_000) == false)
    }

    @Test func hiddenUntilFirstPoke() {
        var transport = VodTransportVisibility()
        #expect(transport.resolve(at: 0) == false)
    }
}
