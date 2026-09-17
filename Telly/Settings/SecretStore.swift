import Foundation
import Security

/// A string-only persistence seam for sensitive credentials — the parental
/// PIN's salt and salted hash. Deliberately separate from ``KeyValueStore``:
/// these values belong in the Keychain, never plaintext `UserDefaults`. Tests
/// inject an in-memory fake; production uses ``KeychainSecretStore``. An unset
/// key reads back nil so callers can detect "no PIN set".
protocol SecretStore {
    func read(_ key: String) -> String?
    func write(_ value: String, _ key: String)
    func remove(_ key: String)
}

/// Real `SecretStore` over the Keychain: generic-password items, scoped to one
/// service, readable only while the device is unlocked and never migrated to a
/// new device. Thin `SecItem*` glue — `read` copies the item, `write` is an
/// add-or-update, `remove` deletes; any non-success status collapses to nil.
struct KeychainSecretStore: SecretStore {
    private let service = "com.johncorser.telly.parental"

    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }

    func read(_ key: String) -> String? {
        var find = query(key)
        find[kSecReturnData as String] = true
        find[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(find as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func write(_ value: String, _ key: String) {
        let attrs: [String: Any] = [
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        if SecItemUpdate(query(key) as CFDictionary, attrs as CFDictionary) == errSecItemNotFound {
            SecItemAdd(query(key).merging(attrs) { $1 } as CFDictionary, nil)
        }
    }

    func remove(_ key: String) {
        SecItemDelete(query(key) as CFDictionary)
    }
}
