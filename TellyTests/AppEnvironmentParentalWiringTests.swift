import Testing
import Foundation
@testable import Telly

/// The composition-root wiring for parental controls: `makeParentalStore` builds
/// a store whose non-sensitive enable toggle shares the settings
/// ``KeyValueStore`` backing, so the flag persists across freshly-built stores.
/// A default install has no PIN. (Construction uses the real ``KeychainSecretStore``
/// but this test never writes a PIN, so it never touches the Keychain.)
@MainActor
struct AppEnvironmentParentalWiringTests {
    private func env() throws -> AppEnvironment {
        let db = try AppDatabase.makeInMemory()
        return AppEnvironment(database: db, settings: SettingsStore(backing: InMemoryKeyValueStore()))
    }

    @Test func freshEnvironmentHasNoPinAndIsDisabled() throws {
        let parental = try env().makeParentalStore()
        #expect(parental.isSet == false)
        #expect(parental.isEnabled == false)
    }

    @Test func enableTogglePersistsThroughSharedSettingsBacking() throws {
        let e = try env()
        e.makeParentalStore().isEnabled = true
        #expect(e.makeParentalStore().isEnabled == true)   // read back via the shared KeyValueStore
    }
}
