import Foundation

/// The colour-scheme preference over the backing ``KeyValueStore``, split into
/// its own extension so ``SettingsStore`` stays within budget (extension
/// precedent: `+Consumers`, `+Keymap`, `+Playlist`). `appearanceThemeRaw`
/// mirrors the coerce-nothing/write-through idiom the picker binds to;
/// `appearanceTheme` derives the typed value the app root applies.
extension SettingsStore {
    /// The stored colour-scheme choice as an `AppearanceTheme` raw value.
    var appearanceThemeRaw: Int {
        get { rawTheme }
        set { rawTheme = newValue; backing.writeInt(newValue, SettingsKey.colorScheme.rawValue) }
    }

    /// The derived colour-scheme preference applied at the app root.
    var appearanceTheme: AppearanceTheme { .from(raw: rawTheme) }
}
