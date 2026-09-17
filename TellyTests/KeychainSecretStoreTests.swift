import Testing
import Foundation
@testable import Telly

/// Round-trips the real Keychain adapter against the simulator keychain with a
/// random account per run (never collides, always cleaned up): an unset key
/// reads nil, a write round-trips, a second write updates in place, and remove
/// clears. If the unit-test host lacks a keychain entitlement this cannot pass
/// (errSecMissingEntitlement -34018) — see the commit notes if it was dropped.
struct KeychainSecretStoreTests {
    @Test func writeReadUpdateRemove() {
        let store = KeychainSecretStore()
        let key = "test-\(UUID().uuidString)"
        defer { store.remove(key) }

        #expect(store.read(key) == nil)
        store.write("hash-a", key)
        #expect(store.read(key) == "hash-a")
        store.write("hash-b", key)   // add-or-update path
        #expect(store.read(key) == "hash-b")
        store.remove(key)
        #expect(store.read(key) == nil)
    }
}
