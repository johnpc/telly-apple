import SwiftUI
import Testing
@testable import Telly

/// The pure colour-scheme mapping: each theme maps to the right `ColorScheme?`
/// (System = no override), raw round-trips, labels are distinct, and an unknown
/// stored raw coerces back to System rather than surfacing a nonsense theme.
struct AppearanceThemeTests {
    @Test func colorSchemeMapping() {
        #expect(AppearanceTheme.system.colorScheme == nil)
        #expect(AppearanceTheme.light.colorScheme == .light)
        #expect(AppearanceTheme.dark.colorScheme == .dark)
    }

    @Test func rawValuesRoundTrip() {
        for theme in AppearanceTheme.allCases {
            #expect(AppearanceTheme.from(raw: theme.rawValue) == theme)
            #expect(theme.id == theme.rawValue)
        }
    }

    @Test func unknownRawDefaultsToSystem() {
        #expect(AppearanceTheme.from(raw: 99) == .system)
        #expect(AppearanceTheme.from(raw: -1) == .system)
    }

    @Test func labelsAreDistinctAndNonEmpty() {
        let labels = AppearanceTheme.allCases.map(\.label)
        #expect(labels == ["System", "Light", "Dark"])
        #expect(Set(labels).count == labels.count)
    }
}
