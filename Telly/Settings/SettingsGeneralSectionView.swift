import SwiftUI

/// The "General" settings group: the 24-hour clock toggle. Pure presentation
/// over the shared ``SettingsStore``; coercion and persistence live in the store.
struct SettingsGeneralSectionView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Section("General") {
            Toggle("24-Hour Clock", isOn: $settings.use24hClock)
        }
    }
}
