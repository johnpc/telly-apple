import SwiftUI

/// The "Remote Control" settings group: how each bare-playback remote key is
/// remapped. One generic ``keymapPicker(_:choice:selection:)`` renders every
/// row from a ``PlayerKeymapChoice`` type, so the four slots share a single
/// picker definition. Pure presentation over the shared ``SettingsStore``.
struct SettingsRemoteSectionView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Section("Remote Control") {
            keymapPicker("OK Button", choice: PlayerOkAction.self,
                         selection: $settings.playerKeyOkRaw)
            keymapPicker("Up / Down", choice: PlayerUpDownAction.self,
                         selection: $settings.playerKeyUpDownRaw)
            keymapPicker("Left / Right", choice: PlayerLeftRightAction.self,
                         selection: $settings.playerKeyLeftRightRaw)
            keymapPicker("Long Press OK", choice: PlayerLongOkAction.self,
                         selection: $settings.playerKeyLongOkRaw)
        }
    }

    @ViewBuilder
    private func keymapPicker<Choice: PlayerKeymapChoice>(
        _ title: String, choice: Choice.Type, selection: Binding<Int>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(Array(Choice.allCases), id: \.rawValue) { option in
                Text(option.title).tag(option.rawValue)
            }
        }
    }
}
