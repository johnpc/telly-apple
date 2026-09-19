import Foundation

/// Snapshots the exportable scalar settings to a `[String: String]` map and
/// applies such a map back, over a ``KeyValueStore`` seam — pure and fully
/// testable with an in-memory fake. `exportable` is the single key list both
/// paths iterate, so the encode/decode surfaces can never drift apart.
enum SettingsSnapshot {
    /// The keys held as Bool in the backing store; every other key is Int.
    private static let boolKeys: Set<SettingsKey> = [.use24hClock]

    /// The keys a backup carries: every scalar preference key.
    static var exportable: [SettingsKey] { SettingsKey.allCases }

    /// Reads the current value of each exportable key into a string map, keyed
    /// by the raw setting key; an unset key is simply absent.
    static func snapshot(from store: KeyValueStore) -> [String: String] {
        var map: [String: String] = [:]
        for key in exportable {
            if boolKeys.contains(key) {
                store.readBool(key.rawValue).map { map[key.rawValue] = String($0) }
            } else {
                store.readInt(key.rawValue).map { map[key.rawValue] = String($0) }
            }
        }
        return map
    }

    /// Writes each recognised, exportable key from `map` back to the store;
    /// unknown keys and un-coercible values are ignored.
    static func restore(_ map: [String: String], into store: KeyValueStore) {
        for key in exportable {
            guard let raw = map[key.rawValue] else { continue }
            if boolKeys.contains(key) {
                Bool(raw).map { store.writeBool($0, key.rawValue) }
            } else {
                Int(raw).map { store.writeInt($0, key.rawValue) }
            }
        }
    }
}
