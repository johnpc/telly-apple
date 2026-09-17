import SwiftUI

/// The "Groups" settings group: a link into the Manage-Groups pane where custom
/// groups are created, renamed and deleted. The model is vended off the cap-safe
/// ``PlaylistsSettingsModel`` carrier (built from the shared database), so no
/// capped file grows. Pure presentation.
struct SettingsGroupsSectionView: View {
    let makeManageGroupsModel: () -> ManageGroupsModel
    let makeCopyChannelsModel: () -> CopyChannelsModel

    var body: some View {
        Section("Groups") {
            NavigationLink("Manage Groups") {
                ManageGroupsScreen(model: makeManageGroupsModel(),
                                   makeCopyChannelsModel: makeCopyChannelsModel)
            }
        }
    }
}
