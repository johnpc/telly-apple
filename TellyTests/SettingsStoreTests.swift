import Testing
@testable import Telly

/// The scalar-preferences store over an in-memory ``KeyValueStore`` fake:
/// default fallback, round-trips, out-of-range coercion, reset, and the derived
/// consumer values that `AppEnvironment` threads into its factories.
@MainActor
struct SettingsStoreTests {
    private func store() -> SettingsStore { SettingsStore(backing: InMemoryKeyValueStore()) }

    @Test func emptyStoreReturnsDefaults() {
        let s = store()
        #expect(s.use24hClock == SettingsDefaults.use24hClock)
        #expect(s.panelTimeoutSeconds == SettingsDefaults.panelTimeoutSeconds)
        #expect(s.epgRefreshHours == SettingsDefaults.epgRefreshHours)
        #expect(s.epgKeepPastDays == SettingsDefaults.epgKeepPastDays)
    }

    @Test func use24hClockRoundTrips() {
        let s = store()
        s.use24hClock = false
        #expect(s.use24hClock == false)
        s.use24hClock = true
        #expect(s.use24hClock == true)
    }

    @Test func panelTimeoutRoundTripsOnAValidChoice() {
        let s = store()
        s.panelTimeoutSeconds = 30
        #expect(s.panelTimeoutSeconds == 30)
    }

    @Test func panelTimeoutCoercesOutOfRangeToNearestChoice() {
        let s = store()
        s.panelTimeoutSeconds = 7            // between 5 and 10, closer to 5
        #expect(s.panelTimeoutSeconds == 5)
        s.panelTimeoutSeconds = 100          // above the max choice
        #expect(s.panelTimeoutSeconds == 30)
    }

    @Test func epgRefreshHoursClampsNegativeToZero() {
        let s = store()
        s.epgRefreshHours = -1
        #expect(s.epgRefreshHours == 0)
    }

    @Test func epgKeepPastDaysClampsNegativeToZero() {
        let s = store()
        s.epgKeepPastDays = -5
        #expect(s.epgKeepPastDays == 0)
    }

    @Test func resetToDefaultsRestoresEverything() {
        let s = store()
        s.use24hClock = false
        s.panelTimeoutSeconds = 30
        s.epgRefreshHours = 6
        s.epgKeepPastDays = 14
        s.resetToDefaults()
        #expect(s.use24hClock == SettingsDefaults.use24hClock)
        #expect(s.panelTimeoutSeconds == SettingsDefaults.panelTimeoutSeconds)
        #expect(s.epgRefreshHours == SettingsDefaults.epgRefreshHours)
        #expect(s.epgKeepPastDays == SettingsDefaults.epgKeepPastDays)
    }

    @Test func derivedConsumersMatchScalarSettings() {
        let s = store()
        s.panelTimeoutSeconds = 10
        s.epgRefreshHours = 12
        s.epgKeepPastDays = 3
        #expect(s.panelTimeouts == PanelTimeouts.forSeconds(10))
        #expect(s.epgRefreshIntervalMs == RefreshScheduler.hoursToMs(12))
        #expect(s.epgKeepPastMs == RefreshScheduler.daysToMs(3))
    }

    @Test func neverRefreshHoursMakeIntervalDisabled() {
        let s = store()
        s.epgRefreshHours = 0
        #expect(s.epgRefreshIntervalMs == 0)
    }

    @Test func standardStoreConstructsOverUserDefaults() {
        _ = SettingsStore.standard
    }
}
