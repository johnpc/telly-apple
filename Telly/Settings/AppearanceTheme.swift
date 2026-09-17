import SwiftUI

/// The user's colour-scheme preference, stored as an `Int` raw value in the
/// scalar settings store and mapped to the SwiftUI `ColorScheme?` applied at the
/// app root. `System` follows the device (`nil` = no override); `Light`/`Dark`
/// force that appearance. `from(raw:)` coerces any out-of-range stored value
/// back to `System`, so a corrupt store can never surface a nonsense theme.
enum AppearanceTheme: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    /// The human-readable picker label.
    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The scheme applied at the app root; `nil` follows the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// The theme for a stored raw value, defaulting to `System` when unknown.
    static func from(raw: Int) -> AppearanceTheme { AppearanceTheme(rawValue: raw) ?? .system }
}
