import SwiftUI

/// The "Appearance" settings group: the colour-scheme picker (System/Light/Dark
/// — applied at the app root via ``SettingsStore/appearanceTheme``), the channel
/// list/panel/guide sort-order picker, and a link into the existing
/// Manage-Visibility flow for per-channel/group visibility.
/// Language/font/logo appearance controls are not yet implemented on Apple and
/// are deliberately omitted rather than shipped as dead settings (plan §1.4).
/// Pure presentation — coercion and persistence live in the store.
struct SettingsAppearanceSectionView: View {
    @Bindable var settings: SettingsStore
    let makeVisibilityEditModel: () -> VisibilityEditModel

    var body: some View {
        Section("Appearance") {
            Picker("Theme", selection: $settings.appearanceThemeRaw) {
                ForEach(AppearanceTheme.allCases) { theme in
                    Text(theme.label).tag(theme.rawValue)
                }
            }
            Picker("Sort Channels", selection: $settings.channelSortRaw) {
                ForEach(ChannelSort.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            NavigationLink("Channel Visibility") {
                ManageVisibilityScreen(model: makeVisibilityEditModel())
            }
        }
    }
}
