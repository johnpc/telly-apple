import Foundation

/// The app's scalar preferences over an injected ``KeyValueStore`` seam: an
/// `@Observable` façade the settings UI binds to and the composition root reads.
/// Values are mirrored in tracked storage (so SwiftUI observes changes) and
/// written through to `backing`; reads coerce into range so a corrupt or
/// out-of-range store can never surface a nonsense setting. Derived consumer
/// values (timeouts, EPG millis) live in `SettingsStore+Consumers`.
@MainActor
@Observable
final class SettingsStore {
    @ObservationIgnored let backing: KeyValueStore
    private var raw24h: Bool
    private var rawTimeout: Int
    private var rawRefresh: Int
    private var rawKeep: Int
    var rawKeyOk: Int
    var rawKeyUpDown: Int
    var rawKeyLeftRight: Int
    var rawKeyLongOk: Int

    init(backing: KeyValueStore) {
        self.backing = backing
        raw24h = backing.readBool(SettingsKey.use24hClock.rawValue) ?? SettingsDefaults.use24hClock
        rawTimeout = backing.readInt(SettingsKey.panelTimeoutSeconds.rawValue) ?? SettingsDefaults.panelTimeoutSeconds
        rawRefresh = backing.readInt(SettingsKey.epgRefreshHours.rawValue) ?? SettingsDefaults.epgRefreshHours
        rawKeep = backing.readInt(SettingsKey.epgKeepPastDays.rawValue) ?? SettingsDefaults.epgKeepPastDays
        rawKeyOk = backing.readInt(SettingsKey.playerKeyOk.rawValue) ?? SettingsDefaults.playerKeyOk
        rawKeyUpDown = backing.readInt(SettingsKey.playerKeyUpDown.rawValue) ?? SettingsDefaults.playerKeyUpDown
        rawKeyLeftRight = backing.readInt(SettingsKey.playerKeyLeftRight.rawValue) ?? SettingsDefaults.playerKeyLeftRight
        rawKeyLongOk = backing.readInt(SettingsKey.playerKeyLongOk.rawValue) ?? SettingsDefaults.playerKeyLongOk
    }

    /// The on-device store backed by the standard user defaults.
    static var standard: SettingsStore { SettingsStore(backing: UserDefaults.standard) }

    /// 24-hour vs 12-hour clock labels in the guide (default: 24-hour).
    var use24hClock: Bool {
        get { raw24h }
        set { raw24h = newValue; backing.writeBool(newValue, SettingsKey.use24hClock.rawValue) }
    }

    /// Overlay auto-hide seconds, snapped to the nearest offered choice.
    var panelTimeoutSeconds: Int {
        get { Self.snap(rawTimeout, to: SettingsDefaults.panelTimeoutChoices) }
        set { rawTimeout = newValue; backing.writeInt(newValue, SettingsKey.panelTimeoutSeconds.rawValue) }
    }

    /// Hours between EPG refreshes; 0 means "Never". Negatives clamp to 0.
    var epgRefreshHours: Int {
        get { max(0, rawRefresh) }
        set { rawRefresh = max(0, newValue); backing.writeInt(rawRefresh, SettingsKey.epgRefreshHours.rawValue) }
    }

    /// Days of ended programmes to keep before trimming. Negatives clamp to 0.
    var epgKeepPastDays: Int {
        get { max(0, rawKeep) }
        set { rawKeep = max(0, newValue); backing.writeInt(rawKeep, SettingsKey.epgKeepPastDays.rawValue) }
    }

    /// Restores every setting to its factory default by clearing the store.
    func resetToDefaults() {
        SettingsKey.allCases.forEach { backing.remove($0.rawValue) }
        raw24h = SettingsDefaults.use24hClock
        rawTimeout = SettingsDefaults.panelTimeoutSeconds
        rawRefresh = SettingsDefaults.epgRefreshHours
        rawKeep = SettingsDefaults.epgKeepPastDays
        rawKeyOk = SettingsDefaults.playerKeyOk
        rawKeyUpDown = SettingsDefaults.playerKeyUpDown
        rawKeyLeftRight = SettingsDefaults.playerKeyLeftRight
        rawKeyLongOk = SettingsDefaults.playerKeyLongOk
    }

    /// The choice nearest `value` (ties resolve to the lower choice).
    private static func snap(_ value: Int, to choices: [Int]) -> Int {
        choices.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }
}
