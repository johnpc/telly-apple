import Foundation
@testable import Telly

/// In-memory ``KeyValueStore`` fake for tests — two distinctly-typed dicts so
/// the store is exercised without touching real `UserDefaults` and without any
/// `Any`. Absent keys read back as nil so the default fallback is observable.
final class InMemoryKeyValueStore: KeyValueStore {
    private var bools: [String: Bool] = [:]
    private var ints: [String: Int] = [:]
    private var strings: [String: String] = [:]

    func readBool(_ key: String) -> Bool? { bools[key] }
    func readInt(_ key: String) -> Int? { ints[key] }
    func readString(_ key: String) -> String? { strings[key] }
    func writeBool(_ value: Bool, _ key: String) { bools[key] = value }
    func writeInt(_ value: Int, _ key: String) { ints[key] = value }
    func writeString(_ value: String, _ key: String) { strings[key] = value }
    func remove(_ key: String) {
        bools[key] = nil
        ints[key] = nil
        strings[key] = nil
    }
}
