import SwiftUI

/// The settings form: General / Playback / Guide-data / Remote-Control /
/// Parental-Controls sections, dismissed via the Done button. Pure presentation
/// — every coercion and write lives in the ``SettingsStore`` / ``ParentalStore``,
/// so this file stays logic-free.
struct SettingsScreen: View {
    @Bindable var settings: SettingsStore
    let parental: ParentalStore
    let backup: SettingsBackupModel
    let playlists: PlaylistsSettingsModel
    let makeVisibilityEditModel: () -> VisibilityEditModel
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                SettingsPlaylistsSectionView(model: playlists)
                SettingsGeneralSectionView(settings: settings)
                SettingsPlaybackSectionView(settings: settings)
                SettingsGuideSectionView(settings: settings,
                                         updateEpgNow: { await playlists.refreshEpgNow() })
                SettingsRemoteSectionView(settings: settings)
                SettingsParentalSectionView(parental: parental, playlists: playlists)
                SettingsBackupSectionView(model: backup)
                SettingsAppearanceSectionView(settings: settings,
                                              makeVisibilityEditModel: makeVisibilityEditModel)
                SettingsAboutSectionView()
                SettingsOtherSectionView(settings: settings)
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
