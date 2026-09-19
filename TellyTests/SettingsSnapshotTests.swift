import Testing
@testable import Telly

/// The pure settings snapshot/restore over a fake ``KeyValueStore``: it captures
/// the exportable scalar keys, coerces string values back to their typed store,
/// and ignores unknown keys.
struct SettingsSnapshotTests {
    @Test func snapshotCapturesScalars() {
        let kv = InMemoryKeyValueStore()
        kv.writeBool(false, SettingsKey.use24hClock.rawValue)
        kv.writeInt(12, SettingsKey.epgRefreshHours.rawValue)
        let map = SettingsSnapshot.snapshot(from: kv)
        #expect(map[SettingsKey.use24hClock.rawValue] == "false")
        #expect(map[SettingsKey.epgRefreshHours.rawValue] == "12")
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

    @Test func restoreIgnoresUncoercibleValues() {
        let kv = InMemoryKeyValueStore()
        SettingsSnapshot.restore([SettingsKey.epgRefreshHours.rawValue: "notanumber",
                                  SettingsKey.use24hClock.rawValue: "notabool"], into: kv)
        #expect(kv.readInt(SettingsKey.epgRefreshHours.rawValue) == nil)
        #expect(kv.readBool(SettingsKey.use24hClock.rawValue) == nil)
    }
}
