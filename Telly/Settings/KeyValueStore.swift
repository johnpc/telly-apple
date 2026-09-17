import Foundation

/// A minimal key-value persistence seam for scalar app preferences. Accessors
/// are distinctly named (`readBool`/`writeBool`…) so they never collide with
/// `UserDefaults`' native `bool(forKey:)`/`set(_:forKey:)`; the real adapter is
/// a thin forward and tests inject an in-memory fake — no real `UserDefaults`,
/// no `Any`. Reads return nil for an unset key so callers can fall back to a
/// default rather than an implicit 0/false.
protocol KeyValueStore {
    func readBool(_ key: String) -> Bool?
    func readInt(_ key: String) -> Int?
    func readString(_ key: String) -> String?
    func writeBool(_ value: Bool, _ key: String)
    func writeInt(_ value: Int, _ key: String)
    func writeString(_ value: String, _ key: String)
    func remove(_ key: String)
}

/// Real persistence over `UserDefaults`. `object(forKey:)` distinguishes an
/// unset key (nil) from a stored `false`/`0`, which `bool`/`integer` alone cannot.
extension UserDefaults: KeyValueStore {
    func readBool(_ key: String) -> Bool? {
        object(forKey: key) != nil ? bool(forKey: key) : nil
    }

    func readInt(_ key: String) -> Int? {
        object(forKey: key) != nil ? integer(forKey: key) : nil
    }

    func readString(_ key: String) -> String? { object(forKey: key) as? String }

    func writeBool(_ value: Bool, _ key: String) { set(value, forKey: key) }
    func writeInt(_ value: Int, _ key: String) { set(value, forKey: key) }
    func writeString(_ value: String, _ key: String) { set(value, forKey: key) }
    func remove(_ key: String) { removeObject(forKey: key) }
}
