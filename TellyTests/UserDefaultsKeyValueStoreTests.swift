import Testing
import Foundation
@testable import Telly

/// The real `UserDefaults` ``KeyValueStore`` adapter, exercised against a
/// transient suite (a fresh `UUID` domain per run) so it never pollutes the
/// shared defaults: unset keys read nil, writes round-trip, and remove clears.
struct UserDefaultsKeyValueStoreTests {
    private func transient() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }

    @Test func unsetKeysReadNil() {
        let store: KeyValueStore = transient()
        #expect(store.readBool("missing") == nil)
        #expect(store.readInt("missing") == nil)
    }

    @Test func writtenValuesRoundTrip() {
        let store: KeyValueStore = transient()
        store.writeBool(false, "flag")   // distinct from the unset-nil case
        store.writeInt(42, "count")
        #expect(store.readBool("flag") == false)
        #expect(store.readInt("count") == 42)
    }

    @Test func removeClearsAValue() {
        let store: KeyValueStore = transient()
        store.writeInt(7, "count")
        store.remove("count")
        #expect(store.readInt("count") == nil)
    }
}
