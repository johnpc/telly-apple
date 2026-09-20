import Foundation

/// The persisted video resize / aspect-ratio preference. Unlike the tracked
/// scalar settings, this reads and writes `backing` directly (it is toggled from
/// the player quick-bar, not bound to a Settings picker), so it needs no stored
/// mirror in the base `SettingsStore` and `resetToDefaults` clears it via the
/// `SettingsKey.allCases` sweep. Corrupt / out-of-range raws fall back to `.fit`.
extension SettingsStore {
    /// The stored resize-mode raw value, defaulting to `.fit` when unset.
    var resizeModeRaw: Int {
        get { backing.readInt(SettingsKey.resizeMode.rawValue) ?? SettingsDefaults.resizeMode }
        set { backing.writeInt(newValue, SettingsKey.resizeMode.rawValue) }
    }

    /// The persisted resize mode the player applies on start / channel change.
    var resizeMode: ResizeMode {
        get { ResizeMode(rawValue: resizeModeRaw) ?? .fit }
        set { resizeModeRaw = newValue.rawValue }
    }
}
