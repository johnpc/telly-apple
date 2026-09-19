import Testing
@testable import Telly

/// The fullscreen tune-time gate over a real ``ParentalStore`` on in-memory
/// backings: it challenges a blocked+enabled channel with a PIN, tunes freely
/// otherwise, verifies via the store (never re-hashing), and waves the
/// just-unlocked channel through exactly once (the `passOnceId` bit). A wrong
/// PIN never clears the prompt or unlocks.
@MainActor
struct PlaybackBlockGateTests {
    private func parental() -> ParentalStore {
        ParentalStore(secret: InMemorySecretStore(), backing: InMemoryKeyValueStore())
    }

    private func armed() -> ParentalStore {
        let p = parental()
        p.set(pin: "1234")
        p.isEnabled = true
        return p
    }

    private func channel(_ id: Int, blocked: Bool) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"),
                      flags: ChannelFlags(blocked: blocked))
    }

    @Test func interceptsBlockedChannelAndRecordsPending() {
        let gate = PlaybackBlockGate(parental: armed())
        #expect(gate.intercept(channel(1, blocked: true)) == true)
        #expect(gate.pending?.id == 1)
    }

    @Test func unblockedChannelTunesFreely() {
        let gate = PlaybackBlockGate(parental: armed())
        #expect(gate.intercept(channel(2, blocked: false)) == false)
        #expect(gate.pending == nil)
    }

    @Test func noChallengeWhenDisabledOrNoPin() {
        let gate = PlaybackBlockGate(parental: parental())     // no PIN, disabled
        #expect(gate.intercept(channel(1, blocked: true)) == false)
        #expect(gate.pending == nil)
    }

    @Test func wrongPinDoesNotUnlockAndKeepsPending() {
        let gate = PlaybackBlockGate(parental: armed())
        _ = gate.intercept(channel(1, blocked: true))
        #expect(gate.unlock(pin: "0000") == nil)
        #expect(gate.pending?.id == 1)
    }

    @Test func correctPinUnlocksAndClearsPending() {
        let gate = PlaybackBlockGate(parental: armed())
        _ = gate.intercept(channel(1, blocked: true))
        #expect(gate.unlock(pin: "1234")?.id == 1)
        #expect(gate.pending == nil)
    }

    @Test func unlockedChannelPassesInterceptExactlyOnce() {
        let gate = PlaybackBlockGate(parental: armed())
        let ch = channel(1, blocked: true)
        _ = gate.intercept(ch)
        _ = gate.unlock(pin: "1234")
        #expect(gate.intercept(ch) == false)   // the immediate tune passes through
        #expect(gate.intercept(ch) == true)    // a later tune re-prompts (D1)
    }

    @Test func dismissClearsPendingWithoutTuning() {
        let gate = PlaybackBlockGate(parental: armed())
        _ = gate.intercept(channel(1, blocked: true))
        gate.dismiss()
        #expect(gate.pending == nil)
    }

    @Test func unlockWithoutPendingReturnsNil() {
        #expect(PlaybackBlockGate(parental: armed()).unlock(pin: "1234") == nil)
    }

    @Test func blocksIsAPureCheckWithoutRecordingPending() {
        let gate = PlaybackBlockGate(parental: armed())
        #expect(gate.blocks(channel(1, blocked: true)) == true)
        #expect(gate.blocks(channel(2, blocked: false)) == false)
        #expect(gate.pending == nil)           // no side effect, unlike intercept
    }

    @Test func blocksIsFalseWhenParentalDisabled() {
        let gate = PlaybackBlockGate(parental: parental())     // no PIN, disabled
        #expect(gate.blocks(channel(1, blocked: true)) == false)
    }
}
