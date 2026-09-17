import Foundation
@testable import Telly

/// In-memory ``SecretStore`` fake for tests — a single `[String: String]` map
/// mirroring ``InMemoryKeyValueStore``. Lets the crypto/policy/store tests run
/// without touching the real Keychain; an absent key reads back nil.
final class InMemorySecretStore: SecretStore {
    private var values: [String: String] = [:]

    func read(_ key: String) -> String? { values[key] }
    func write(_ value: String, _ key: String) { values[key] = value }
    func remove(_ key: String) { values[key] = nil }
}
