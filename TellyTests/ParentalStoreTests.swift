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
}
