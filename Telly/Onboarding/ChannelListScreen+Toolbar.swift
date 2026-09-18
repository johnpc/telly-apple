import SwiftUI

/// The channel-list primary-action toolbar, split out to keep `ChannelListScreen`
/// within the source-line budget: links to the Guide, the recently-watched
/// History screen, and the Manage-Favorites / Manage-Visibility editors, the
/// Add-playlist action, and the Settings button that presents the settings sheet.
extension ChannelListScreen {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                GuideGridScreen(model: makeGuideGridModel(), makeEngine: makeEngine,
                                makeCatchupModel: makeCatchupModel)
            } label: { barLabel("Guide", "tv") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                HistoryScreen(model: makeHistoryModel(), makeEngine: makeEngine)
            } label: { barLabel("History", "clock.arrow.circlepath") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink { SearchScreen(model: makeSearchModel()) }
                label: { barLabel("Search", "magnifyingglass") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                VodBrowseScreen(model: makeVodBrowseModel(),
                                makePlaybackModel: makeVodPlaybackModel)
            } label: { Label("Movies", systemImage: "film") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                MyListScreen(model: makeMyListModel(), makeEngine: makeEngine)
            } label: { Label("My List", systemImage: "bookmark") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink { ManageFavoritesScreen(model: makeChannelEditModel(nil)) }
                label: { barLabel("Favorites", "star") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink { ManageVisibilityScreen(model: makeVisibilityEditModel()) }
                label: { barLabel("Visibility", "eye") }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(action: onAdd) { barLabel("Add", "plus") }
        }
        ToolbarItem(placement: .primaryAction) {
            Button { showSettings = true } label: { barLabel("Settings", "gearshape") }
        }
    }

    /// A toolbar item's label. tvOS renders an icon-only pill: plain-text buttons
    /// in the tvOS navigation bar wash out to an illegible bright-white capsule
    /// (light label on a light fill), whereas the icon pill reads crisply — the
    /// same treatment the Movies / My List items already use. iPhone / iPad keep
    /// the legible text title, so their bar is unchanged.
    @ViewBuilder func barLabel(_ title: String, _ symbol: String) -> some View {
        #if os(tvOS)
        Label(title, systemImage: symbol).labelStyle(.iconOnly)
        #else
        Text(title)
        #endif
    }
}
