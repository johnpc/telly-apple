import SwiftUI

/// The settings form: General / Playback / Guide-data / Remote-Control
/// sections, dismissed via the Done button. Pure presentation — every coercion
/// and write lives in the ``SettingsStore``, so this file stays logic-free.
struct SettingsScreen: View {
    @Bindable var settings: SettingsStore
    let backup: SettingsBackupModel
    let playlists: PlaylistsSettingsModel
    let makeVisibilityEditModel: () -> VisibilityEditModel
    let clearVodPositions: () -> Void
    let onClose: () -> Void
    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        NavigationStack {
            Form {
                SettingsPlaylistsSectionView(model: playlists)
                SettingsGroupsSectionView(makeManageGroupsModel: playlists.makeManageGroupsModel,
                                          makeCopyChannelsModel: playlists.makeCopyChannelsModel)
                SettingsGeneralSectionView(settings: settings)
                SettingsPlaybackSectionView(settings: settings)
                SettingsVodSectionView(settings: settings, onClear: clearVodPositions)
                SettingsGuideSectionView(settings: settings,
                                         updateEpgNow: { await playlists.refreshEpgNow() },
                                         makeEpgAssignmentModel: playlists.makeEpgAssignmentModel)
                SettingsRemoteSectionView(settings: settings)
                SettingsBackupSectionView(model: backup)
                SettingsAppearanceSectionView(settings: settings,
                                              makeVisibilityEditModel: makeVisibilityEditModel)
                SettingsAboutSectionView()
                SettingsOtherSectionView(settings: settings)
            }
            #if !os(tvOS)
            .frame(maxWidth: CompactLayout.settingsFormMaxWidth(sizeClass) ?? .infinity)
            .frame(maxWidth: .infinity)
            #endif
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onClose) { doneLabel }
                }
            }
        }
    }

    /// The Done button's label. tvOS renders a bare xmark `Image` (not a `Label`):
    /// a plain "Done" text button in the tvOS navigation bar washes out to an
    /// illegible bright-white capsule, and the bar re-expands a `Label` back to a
    /// truncated title even under `.labelStyle(.iconOnly)` — a lone `Image` has no
    /// title to expand, so the icon reads crisply (the accessibility label keeps
    /// VoiceOver naming). iPhone / iPad keep the legible "Done" text title.
    @ViewBuilder private var doneLabel: some View {
        #if os(tvOS)
        Image(systemName: "xmark").accessibilityLabel(Text("Done"))
        #else
        Text("Done")
        #endif
    }
}
