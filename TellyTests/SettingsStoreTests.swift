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
        #expect(s.updateOnPlaylistsChange == SettingsDefaults.updateOnPlaylistsChange)
        #expect(s.saveSearchHistory == SettingsDefaults.saveSearchHistory)
        #expect(s.vodRememberPosition == SettingsDefaults.vodRememberPosition)
    }

    @Test func vodRememberPositionDefaultsOnRoundTripsAndResets() {
        let s = store()
        #expect(s.vodRememberPosition == true)          // resume on by default
        s.vodRememberPosition = false
        #expect(s.vodRememberPosition == false)
        #expect(store2(s).vodRememberPosition == false)  // persisted through backing
        s.resetToDefaults()
        #expect(s.vodRememberPosition == SettingsDefaults.vodRememberPosition)
    }

    @Test func saveSearchHistoryRoundTripsAndResets() {
        let s = store()
        s.saveSearchHistory = false
        #expect(s.saveSearchHistory == false)
        #expect(store2(s).saveSearchHistory == false)   // persisted through backing
        s.resetToDefaults()
        #expect(s.saveSearchHistory == SettingsDefaults.saveSearchHistory)
    }

    @Test func updateOnPlaylistsChangeRoundTrips() {
        let s = store()
        s.updateOnPlaylistsChange = true
        #expect(s.updateOnPlaylistsChange == true)
        #expect(store2(s).updateOnPlaylistsChange == true)   // persisted through backing
    }

    @Test func resetRestoresUpdateOnPlaylistsChange() {
        let s = store()
        s.updateOnPlaylistsChange = true
        s.resetToDefaults()
        #expect(s.updateOnPlaylistsChange == SettingsDefaults.updateOnPlaylistsChange)
    }

    private func store2(_ from: SettingsStore) -> SettingsStore { SettingsStore(backing: from.backing) }

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

    @Test func resizeModeDefaultsToFitRoundTripsAndResets() {
        let s = store()
        #expect(s.resizeMode == .fit)               // TiviMate default
        s.resizeMode = .ratio16x9
        #expect(s.resizeMode == .ratio16x9)
        #expect(store2(s).resizeMode == .ratio16x9)  // persisted through backing
        s.resetToDefaults()
        #expect(s.resizeMode == .fit)
    }

    @Test func corruptResizeRawCoercesToFit() {
        let s = store()
        s.resizeModeRaw = 9_999
        #expect(s.resizeMode == .fit)
    }

    @Test func channelSortDefaultsToPlaylistOrderRoundTripsAndResets() {
        let s = store()
        #expect(s.channelSort == .default)           // TiviMate playlist order
        s.channelSortRaw = ChannelSort.nameAZ.rawValue
        #expect(s.channelSort == .nameAZ)
        #expect(store2(s).channelSort == .nameAZ)    // persisted through backing
        s.resetToDefaults()
        #expect(s.channelSort == .default)
    }

    @Test func corruptChannelSortRawCoercesToDefault() {
        let s = store()
        s.channelSortRaw = 9_999
        #expect(s.channelSort == .default)
    }

    @Test func emptyStoreReturnsKeymapDefaults() {
        let s = store()
        #expect(s.playerKeyOkRaw == SettingsDefaults.playerKeyOk)
        #expect(s.playerKeyUpDownRaw == SettingsDefaults.playerKeyUpDown)
        #expect(s.playerKeyLeftRightRaw == SettingsDefaults.playerKeyLeftRight)
        #expect(s.playerKeyLongOkRaw == SettingsDefaults.playerKeyLongOk)
    }

    @Test func keymapRawsRoundTrip() {
        let s = store()
        s.playerKeyOkRaw = PlayerOkAction.channelsList.rawValue
        s.playerKeyUpDownRaw = PlayerUpDownAction.switchChannels.rawValue
        s.playerKeyLeftRightRaw = PlayerLeftRightAction.switchChannels.rawValue
        s.playerKeyLongOkRaw = PlayerLongOkAction.channelsList.rawValue
        #expect(s.playerKeyOkRaw == PlayerOkAction.channelsList.rawValue)
        #expect(s.playerKeyUpDownRaw == PlayerUpDownAction.switchChannels.rawValue)
        #expect(s.playerKeyLeftRightRaw == PlayerLeftRightAction.switchChannels.rawValue)
        #expect(s.playerKeyLongOkRaw == PlayerLongOkAction.channelsList.rawValue)
    }

    @Test func defaultKeymapMatchesActionDefaults() {
        let s = store()
        #expect(s.playerKeymap.ok == .showInfo)
        #expect(s.playerKeymap.upDown == .showInfo)
        #expect(s.playerKeymap.leftRight == .nothing)
        #expect(s.playerKeymap.longOk == .quickMenu)
        #expect(SettingsStore.from(settings: s).upDown == s.playerKeymap.upDown)
    }

    @Test func outOfRangeKeymapRawCoercesToDefaultViaDerivation() {
        let s = store()
        s.playerKeyUpDownRaw = Int.max          // corrupt / out-of-range
        s.playerKeyLeftRightRaw = -1            // negative
        #expect(s.playerKeymap.upDown == .showInfo)
        #expect(s.playerKeymap.leftRight == .nothing)
    }

    @Test func resetToDefaultsRestoresKeymap() {
        let s = store()
        s.playerKeyOkRaw = PlayerOkAction.nothing.rawValue
        s.playerKeyUpDownRaw = PlayerUpDownAction.switchChannels.rawValue
        s.playerKeyLeftRightRaw = PlayerLeftRightAction.switchChannels.rawValue
        s.playerKeyLongOkRaw = PlayerLongOkAction.channelsList.rawValue
        s.resetToDefaults()
        #expect(s.playerKeyOkRaw == SettingsDefaults.playerKeyOk)
        #expect(s.playerKeyUpDownRaw == SettingsDefaults.playerKeyUpDown)
        #expect(s.playerKeyLeftRightRaw == SettingsDefaults.playerKeyLeftRight)
        #expect(s.playerKeyLongOkRaw == SettingsDefaults.playerKeyLongOk)
    }

    @Test func remappedUpDownChangesResolvedCommand() {
        let s = store()
        #expect(PlaybackKeyPolicy.command(overlay: .none, key: .up, keymap: s.playerKeymap) == .showInfo)
        s.playerKeyUpDownRaw = PlayerUpDownAction.switchChannels.rawValue
        #expect(PlaybackKeyPolicy.command(overlay: .none, key: .up, keymap: s.playerKeymap) == .zap(delta: 1))
        #expect(PlaybackKeyPolicy.command(overlay: .none, key: .down, keymap: s.playerKeymap) == .zap(delta: -1))
    }
}
