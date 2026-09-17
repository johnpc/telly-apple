import SwiftUI

/// The per-playlist Manage-groups pane: one enable/disable toggle per group the
/// playlist defines (derived from its channels). Disabling a group drops its
/// channels from the guide/live feed via the shared ``PlaylistGroupFilter``.
/// Pure presentation — the group list and the toggle writes are
/// ``PlaylistsSettingsModel`` calls; each toggle binds per group by name.
struct PlaylistGroupsScreen: View {
    @Bindable var model: PlaylistsSettingsModel
    let url: String

    var body: some View {
        List(model.groupNames(for: url), id: \.self) { group in
            Toggle(group, isOn: Binding(
                get: { model.groupEnabled(url: url, group: group) },
                set: { model.setGroupEnabled(url: url, group: group, $0) }))
        }
        .navigationTitle("Manage Groups")
    }
}
