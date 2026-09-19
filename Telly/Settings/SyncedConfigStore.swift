import Foundation
import Security

/// The small, portable snapshot of the user's provider config that must outlive
/// an app uninstall and follow them across devices: their playlist(s) (name +
/// URL + auto-EPG URL) and any custom EPG sources. Reuses the backup value types
/// so there is one serialised shape for both features. The URLs embed provider
/// tokens, so this only ever lives in the (synchronizable) Keychain — never in
/// plaintext `UserDefaults`/iCloud KVS or any committed file.
struct SyncedConfig: Codable, Equatable {
    var playlists: [BackupPlaylist]
    var epgSources: [BackupEpgSource]

    /// True when there is nothing worth persisting — the store clears rather than
    /// saves an empty config so a user who removed every playlist isn't "restored".
    var isEmpty: Bool { playlists.isEmpty }

    /// JSON text for the one Keychain blob; nil only on an (impossible) encode fail.
    func encoded() -> String? {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
    }

    /// Decodes the Keychain blob back; nil on malformed/absent JSON.
    static func decode(_ text: String) -> SyncedConfig? {
        try? JSONDecoder().decode(SyncedConfig.self, from: Data(text.utf8))
    }
}

/// Persistence seam for the cross-reinstall / cross-device provider config.
/// Production is Keychain-backed and synchronizable; tests inject an in-memory
/// fake. An absent config reads back nil so the launch restorer can detect
/// "nothing saved yet".
protocol SyncedConfigStore {
    func load() -> SyncedConfig?
    func save(_ config: SyncedConfig)
    func clear()
}

/// Real ``SyncedConfigStore`` over the synchronizable Keychain. It uses the
/// ``KeychainSecretStore`` glue — configured `synchronizable` with
/// `AfterFirstUnlock` accessibility so the single JSON blob survives uninstall
/// and rides iCloud Keychain across the user's devices. No new app entitlement
/// is needed (it rides the standard iCloud Keychain).
struct KeychainSyncedConfigStore: SyncedConfigStore {
    /// The single Keychain account holding the whole config as one JSON blob.
    static let account = "config.v1"
    private let secret: SecretStore

    init(secret: SecretStore = KeychainSecretStore(
        service: "com.johncorser.telly.synced",
        synchronizable: true,
        accessible: kSecAttrAccessibleAfterFirstUnlock)) {
        self.secret = secret
    }

    func load() -> SyncedConfig? { secret.read(Self.account).flatMap(SyncedConfig.decode) }
    func save(_ config: SyncedConfig) { config.encoded().map { secret.write($0, Self.account) } }
    func clear() { secret.remove(Self.account) }
}
