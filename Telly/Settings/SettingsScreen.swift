import SwiftUI

/// The settings form: General / Playback / Guide-data / Remote-Control sections over the shared
/// ``SettingsStore``, dismissed via the Done button. Pure presentation — every
/// coercion and write lives in the store, so this file stays logic-free.
struct SettingsScreen: View {
    @Bindable var settings: SettingsStore
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                SettingsGeneralSectionView(settings: settings)
                SettingsPlaybackSectionView(settings: settings)
                SettingsGuideSectionView(settings: settings)
                SettingsRemoteSectionView(settings: settings)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
}
