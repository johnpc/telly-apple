import Foundation

/// The remappable player-key choices as stored `Int` raw values, plus the
/// derived ``PlayerKeymap`` the playback policy consumes. Each accessor mirrors
/// the store's coerce-nothing/write-through idiom: get returns the tracked raw
/// var, set updates it and persists through `backing`. The pure derivation in
/// `PlayerKeymap.from(okRaw:…)` coerces any out-of-range raw back to its default.
extension SettingsStore {
    /// OK's bare-playback action, as a `PlayerOkAction` raw value.
    var playerKeyOkRaw: Int {
        get { rawKeyOk }
        set { rawKeyOk = newValue; backing.writeInt(newValue, SettingsKey.playerKeyOk.rawValue) }
    }

    /// UP/DOWN's bare-playback action, as a `PlayerUpDownAction` raw value.
    var playerKeyUpDownRaw: Int {
        get { rawKeyUpDown }
        set { rawKeyUpDown = newValue; backing.writeInt(newValue, SettingsKey.playerKeyUpDown.rawValue) }
    }

    /// LEFT/RIGHT's bare-playback action, as a `PlayerLeftRightAction` raw value.
    var playerKeyLeftRightRaw: Int {
        get { rawKeyLeftRight }
        set { rawKeyLeftRight = newValue; backing.writeInt(newValue, SettingsKey.playerKeyLeftRight.rawValue) }
    }

    /// A held OK's action, as a `PlayerLongOkAction` raw value.
    var playerKeyLongOkRaw: Int {
        get { rawKeyLongOk }
        set { rawKeyLongOk = newValue; backing.writeInt(newValue, SettingsKey.playerKeyLongOk.rawValue) }
    }

    /// The derived keymap the playback policy consumes for its bare-playback keys.
    var playerKeymap: PlayerKeymap {
        .from(okRaw: rawKeyOk, upDownRaw: rawKeyUpDown,
              leftRightRaw: rawKeyLeftRight, longOkRaw: rawKeyLongOk)
    }

    /// Adapter reading the stored raws out of a settings store into a keymap.
    static func from(settings: SettingsStore) -> PlayerKeymap { settings.playerKeymap }
}
