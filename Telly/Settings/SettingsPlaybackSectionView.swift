import SwiftUI

/// The "Playback" settings group: how long the on-screen overlay panels linger
/// before auto-hiding, chosen from the offered second values.
struct SettingsPlaybackSectionView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Section("Playback") {
            Picker("Panels Timeout", selection: $settings.panelTimeoutSeconds) {
                ForEach(SettingsDefaults.panelTimeoutChoices, id: \.self) { seconds in
                    Text("\(seconds) s").tag(seconds)
                }
            }
        }
    }
}
