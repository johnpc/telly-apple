import Testing
@testable import Telly

/// The composition-root wiring for the fullscreen block gate: `makeLivePlaybackModel`
/// threads the app's shared ``ParentalStore`` into a live ``PlaybackBlockGate`` on
/// the model, so a blocked channel is challenged at playback time in the real app.
/// Identity (not a seeded PIN) is asserted so the test never touches the Keychain
/// (the real ``KeychainSecretStore`` backs `parentalStore`); the gate's blocking
/// behaviour itself is covered by the in-memory gate/model tests.
@MainActor
struct LivePlaybackBlockWiringTests {
    private func env() throws -> AppEnvironment {
        AppEnvironment(database: try AppDatabase.makeInMemory(),
                       settings: SettingsStore(backing: InMemoryKeyValueStore()))
    }

    @Test func modelHasABlockGate() throws {
        let model = try env().makeLivePlaybackModel(engineFactory: { FakePlayerEngine() })
        #expect(model.blockGate != nil)
    }

    @Test func gateSharesTheAppParentalStore() throws {
        let e = try env()
        let model = e.makeLivePlaybackModel(engineFactory: { FakePlayerEngine() })
        #expect(model.blockGate?.parental === e.parentalStore)
    }
}
