import SwiftUI

/// The channel-list primary-action toolbar, split out to keep `ChannelListScreen`
/// within the source-line budget: links to the Guide, the recently-watched
/// History screen, and the Manage-Favorites / Manage-Visibility editors, the
/// Add-playlist action, and the Settings button that presents the settings sheet.
extension ChannelListScreen {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Guide") {
                GuideGridScreen(model: makeGuideGridModel(), makeEngine: makeEngine,
                                makeCatchupModel: makeCatchupModel)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("History") {
                HistoryScreen(model: makeHistoryModel(), makeEngine: makeEngine)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Search") {
                SearchScreen(model: makeSearchModel())
            }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                VodBrowseScreen(model: makeVodBrowseModel())
            } label: {
                Label("Movies", systemImage: "film")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Favorites") { ManageFavoritesScreen(model: makeChannelEditModel(nil)) }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink("Visibility") { ManageVisibilityScreen(model: makeVisibilityEditModel()) }
        }
        ToolbarItem(placement: .primaryAction) { Button("Add", action: onAdd) }
        ToolbarItem(placement: .primaryAction) {
            Button("Settings") { showSettings = true }
        }
    }
}
