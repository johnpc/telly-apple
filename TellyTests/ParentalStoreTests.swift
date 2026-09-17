import Testing
@testable import Telly

/// The parental-controls store over in-memory ``SecretStore`` +
/// ``KeyValueStore`` fakes: set/verify/clear, the master enable toggle round-
/// trip and its persistence path, invalid-PIN rejection, and the security
/// invariant that the stored credential is never the raw PIN.
@MainActor
struct ParentalStoreTests {
    private let secret = InMemorySecretStore()
    private let backing = InMemoryKeyValueStore()

    private func store() -> ParentalStore { ParentalStore(secret: secret, backing: backing) }

    /// A store over its own fresh backings, so gate scenarios don't share the
    /// enable flag / hash written by a sibling store in the same test.
    private func freshStore() -> ParentalStore {
        ParentalStore(secret: InMemorySecretStore(), backing: InMemoryKeyValueStore())
    }

    private func channel(blocked: Bool) -> ChannelEntity {
        ChannelEntity(id: 1, playlistId: 1, number: 1, sortIndex: 1,
                      source: ChannelSource(name: "Ch", groupTitle: "Live", streamUrl: "http://x/1"),
                      flags: ChannelFlags(blocked: blocked))
    }

    @Test func freshStoreHasNoPin() {
        #expect(store().isSet == false)
    }

    @Test func setThenVerifyRoundTrips() {
        let s = store()
        #expect(s.set(pin: "1234") == true)
        #expect(s.isSet == true)
        #expect(s.verify(pin: "1234") == true)
        #expect(s.verify(pin: "0000") == false)
    }

    @Test func storedHashIsNotThePlaintextPin() {
        let s = store()
        s.set(pin: "1234")
        let stored = secret.read(ParentalStore.hashKey)
        #expect(stored != nil)
        #expect(stored != "1234")                                   // no plaintext leaked
    }

    @Test func invalidPinIsRejectedAndNotStored() {
        let s = store()
        #expect(s.set(pin: "12") == false)
        #expect(s.set(pin: "12a4") == false)
        #expect(s.isSet == false)
        #expect(s.verify(pin: "12") == false)
    }

    @Test func clearRemovesThePin() {
        let s = store()
        s.set(pin: "4321")
        #expect(s.isSet == true)
        s.clear()
        #expect(s.isSet == false)
        #expect(s.verify(pin: "4321") == false)
    }

    @Test func verifyIsFalseWhenNoPinSet() {
        #expect(store().verify(pin: "1234") == false)
    }

    @Test func isEnabledDefaultsFalseAndRoundTrips() {
        let s = store()
        #expect(s.isEnabled == false)
        s.isEnabled = true
        #expect(s.isEnabled == true)
    }

    @Test func isEnabledPersistsAcrossStoresOverSameBacking() {
        store().isEnabled = true
        // A freshly-constructed store over the same backing reads the flag back,
        // proving the value went through the KeyValueStore, not just tracked state.
        #expect(store().isEnabled == true)
    }

    @Test func clearDisablesEnforcement() {
        let s = store()
        s.set(pin: "1234")
        s.isEnabled = true
        s.clear()
        #expect(s.isEnabled == false)
    }

    @Test func mustChallengeOnlyWhenBlockedWithPinAndEnabled() {
        let s = freshStore()
        s.set(pin: "1234")
        s.isEnabled = true
        #expect(s.mustChallenge(channel(blocked: true)) == true)
        #expect(s.mustChallenge(channel(blocked: false)) == false)   // unblocked tunes freely
    }

    @Test func mustChallengeFalseWithoutPin() {
        let s = freshStore()
        s.isEnabled = true                                           // enabled but no PIN set
        #expect(s.mustChallenge(channel(blocked: true)) == false)
    }

    @Test func mustChallengeFalseWhenEnforcementDisabled() {
        let s = freshStore()
        s.set(pin: "1234")                                           // PIN set but toggle off
        #expect(s.mustChallenge(channel(blocked: true)) == false)
    }

    @Test func wrongPinNeverUnlocksABlockedChannel() {
        // The invariant the row's challenge closure relies on: a blocked+enabled
        // channel with a PIN demands a challenge, and only the correct PIN
        // verifies — so a wrong/blank PIN returns false and never sets a target.
        let s = freshStore()
        s.set(pin: "1234")
        s.isEnabled = true
        let locked = channel(blocked: true)
        #expect(s.mustChallenge(locked) == true)     // tap presents the challenge, not the player
        #expect(s.verify(pin: "0000") == false)      // wrong PIN → closure returns false → no tune
        #expect(s.verify(pin: "1234") == true)       // only the correct PIN unlocks it
    }
}
