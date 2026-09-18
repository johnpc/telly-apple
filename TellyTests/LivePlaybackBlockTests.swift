import Testing
@testable import Telly

/// The live orchestrator gated by ``PlaybackBlockGate``: a blocked channel is
/// intercepted on cold-start restore and on an explicit tune (so it never loads
/// the stream), and only a correct PIN via ``submitBlockPin(_:)`` tunes it.
/// Composed over ``FakePlayerEngine`` + a real ``ParentalStore`` on in-memory
/// backings so the PIN path is exercised end-to-end without the Keychain.
@MainActor
struct LivePlaybackBlockTests {
    private func armedGate() -> PlaybackBlockGate {
        let p = ParentalStore(secret: InMemorySecretStore(), backing: InMemoryKeyValueStore())
        p.set(pin: "1234")
        p.isEnabled = true
        return PlaybackBlockGate(parental: p)
    }

    private func ch(_ id: Int, blocked: Bool) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"),
                      flags: ChannelFlags(blocked: blocked))
    }

    private func model(_ engine: FakePlayerEngine, _ channels: [ChannelEntity],
                       gate: PlaybackBlockGate, stored: Int?) -> LivePlaybackModel {
        LivePlaybackModel(engine: engine, channels: channels,
                          now: { 0 }, persistLastChannel: { _ in },
                          loadLastChannel: { stored }, onExitToGuide: {}, blockGate: gate)
    }

    @Test func startInterceptsBlockedRestoredChannel() {
        let engine = FakePlayerEngine()
        let gate = armedGate()
        let m = model(engine, [ch(10, blocked: true)], gate: gate, stored: 10)
        m.start()
        #expect(engine.loaded.isEmpty)          // never loaded the blocked stream
        #expect(m.current == nil)
        #expect(gate.pending?.id == 10)         // challenge is up
    }

    @Test func tuneInterceptsBlockedChannel() {
        let engine = FakePlayerEngine()
        let gate = armedGate()
        let m = model(engine, [ch(20, blocked: true)], gate: gate, stored: nil)
        m.tune(ch(20, blocked: true))
        #expect(engine.loaded.isEmpty)
        #expect(gate.pending?.id == 20)
    }

    @Test func correctPinTunesTheUnlockedChannel() {
        let engine = FakePlayerEngine()
        let gate = armedGate()
        let m = model(engine, [ch(10, blocked: true)], gate: gate, stored: 10)
        m.start()
        #expect(m.submitBlockPin("1234") == true)
        #expect(m.current?.id == 10)
        #expect(engine.loaded == ["http://127.0.0.1/10.ts"])
        #expect(gate.pending == nil)
    }

    @Test func wrongPinDoesNotTune() {
        let engine = FakePlayerEngine()
        let gate = armedGate()
        let m = model(engine, [ch(10, blocked: true)], gate: gate, stored: 10)
        m.start()
        #expect(m.submitBlockPin("0000") == false)
        #expect(engine.loaded.isEmpty)
        #expect(gate.pending?.id == 10)
    }

    @Test func unblockedChannelStartsNormallyWithGate() {
        let engine = FakePlayerEngine()
        let m = model(engine, [ch(10, blocked: false)], gate: armedGate(), stored: 10)
        m.start()
        #expect(m.current?.id == 10)
        #expect(engine.loaded == ["http://127.0.0.1/10.ts"])
    }
}
