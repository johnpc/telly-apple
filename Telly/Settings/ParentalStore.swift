import Foundation

/// The parental-controls state over two seams: a ``SecretStore`` holding the
/// PIN's salt and salted hash (Keychain only — never plaintext), and the shared
/// ``KeyValueStore`` holding only the non-sensitive `parentalEnabled` toggle.
/// The `@Observable` enable flag is mirrored in tracked storage and written
/// through to the backing (as ``SettingsStore`` does) so SwiftUI observes it;
/// the hash never touches the KeyValueStore.
@MainActor
@Observable
final class ParentalStore {
    /// ``SecretStore`` accounts for the salted hash and salt — Keychain keys,
    /// not ``SettingsKey`` cases.
    static let hashKey = "parental.pinHash"
    static let saltKey = "parental.pinSalt"

    @ObservationIgnored let secret: SecretStore
    @ObservationIgnored let backing: KeyValueStore
    private var rawEnabled: Bool

    init(secret: SecretStore, backing: KeyValueStore) {
        self.secret = secret
        self.backing = backing
        rawEnabled = backing.readBool(SettingsKey.parentalEnabled.rawValue) ?? SettingsDefaults.parentalEnabled
    }

    /// True once a PIN has been set (Android `hasPin`); read straight from the
    /// Keychain so it reflects the real credential state.
    var isSet: Bool { secret.read(Self.hashKey) != nil }

    /// The master enable toggle — the only parental value that is non-sensitive
    /// and so lives in the KeyValueStore rather than the Keychain.
    var isEnabled: Bool {
        get { rawEnabled }
        set { rawEnabled = newValue; backing.writeBool(newValue, SettingsKey.parentalEnabled.rawValue) }
    }

    /// Sets (or replaces) the PIN. Rejects a malformed PIN via ``PinPolicy``,
    /// writing nothing and returning false; otherwise generates a fresh salt and
    /// stores the salt + salted hash in the Keychain, returning true.
    @discardableResult
    func set(pin: String) -> Bool {
        guard PinPolicy.isValid(pin) else { return false }
        let salt = PinHasher.newSalt()
        secret.write(salt, Self.saltKey)
        secret.write(PinHasher.hash(pin: pin, salt: salt), Self.hashKey)
        return true
    }

    /// Verifies `pin` against the stored salt + hash in constant time; false if
    /// no PIN is set.
    func verify(pin: String) -> Bool {
        guard let salt = secret.read(Self.saltKey),
              let expected = secret.read(Self.hashKey) else { return false }
        return PinHasher.matches(pin: pin, salt: salt, expected: expected)
    }

    /// Removes the stored PIN (salt + hash) and disables enforcement.
    func clear() {
        secret.remove(Self.saltKey)
        secret.remove(Self.hashKey)
        isEnabled = false
    }
}
