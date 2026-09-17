import SwiftUI

/// The settings form: General / Playback / Guide-data / Remote-Control /
/// Parental-Controls sections, dismissed via the Done button. Pure presentation
/// — every coercion and write lives in the ``SettingsStore`` / ``ParentalStore``,
/// so this file stays logic-free.
struct SettingsScreen: View {
    @Bindable var settings: SettingsStore
    let parental: ParentalStore
    let backup: SettingsBackupModel
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                SettingsGeneralSectionView(settings: settings)
                SettingsPlaybackSectionView(settings: settings)
                SettingsGuideSectionView(settings: settings)
                SettingsRemoteSectionView(settings: settings)
                SettingsParentalSectionView(parental: parental)
                SettingsBackupSectionView(model: backup)
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
