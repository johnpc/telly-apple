import Testing
@testable import Telly

/// The pure settings snapshot/restore over a fake ``KeyValueStore``: it captures
/// the exportable scalar keys, EXCLUDES parental-lock state on both directions,
/// coerces string values back to their typed store, and ignores unknown keys.
struct SettingsSnapshotTests {
    @Test func snapshotCapturesScalarsButExcludesParental() {
        let kv = InMemoryKeyValueStore()
        kv.writeBool(false, SettingsKey.use24hClock.rawValue)
        kv.writeInt(12, SettingsKey.epgRefreshHours.rawValue)
        kv.writeBool(true, SettingsKey.parentalEnabled.rawValue)
        let map = SettingsSnapshot.snapshot(from: kv)
        #expect(map[SettingsKey.use24hClock.rawValue] == "false")
        #expect(map[SettingsKey.epgRefreshHours.rawValue] == "12")
        // The parental-lock toggle is never exported.
        #expect(map[SettingsKey.parentalEnabled.rawValue] == nil)
        #expect(SettingsSnapshot.excluded.contains(.parentalEnabled))
    }

    @Test func restoreCoercesRecognisedKeys() {
        let kv = InMemoryKeyValueStore()
        SettingsSnapshot.restore([SettingsKey.use24hClock.rawValue: "false",
                                  SettingsKey.epgKeepPastDays.rawValue: "14",
                                  "totallyUnknownKey": "9"], into: kv)
        #expect(kv.readBool(SettingsKey.use24hClock.rawValue) == false)
        #expect(kv.readInt(SettingsKey.epgKeepPastDays.rawValue) == 14)
        #expect(kv.readInt("totallyUnknownKey") == nil)
    }

    @Test func restoreRefusesToWriteParentalState() {
        let kv = InMemoryKeyValueStore()
        // Even if a crafted backup carries parentalEnabled, restore must not
        // apply it — importing a file can never disable parental controls.
        SettingsSnapshot.restore([SettingsKey.parentalEnabled.rawValue: "false"], into: kv)
        #expect(kv.readBool(SettingsKey.parentalEnabled.rawValue) == nil)
    }

    @Test func restoreIgnoresUncoercibleValues() {
        let kv = InMemoryKeyValueStore()
        SettingsSnapshot.restore([SettingsKey.epgRefreshHours.rawValue: "notanumber",
                                  SettingsKey.use24hClock.rawValue: "notabool"], into: kv)
        #expect(kv.readInt(SettingsKey.epgRefreshHours.rawValue) == nil)
        #expect(kv.readBool(SettingsKey.use24hClock.rawValue) == nil)
    }
}
