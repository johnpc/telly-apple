import SwiftUI

/// The channel-list primary-action toolbar, split out to keep `ChannelListScreen`
/// within the source-line budget: links to the Guide, the recently-watched
/// History screen, and the Manage-Favorites / Manage-Visibility editors, the
/// Add-playlist action, and the Settings button that presents the settings sheet.
extension ChannelListScreen {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                GuideStageScreen(stage: liveStage)
            } label: { barLabel("Guide", "tv") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                HistoryScreen(model: makeHistoryModel(), liveStage: liveStage)
            } label: { barLabel("History", "clock.arrow.circlepath") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink { SearchScreen(model: makeSearchModel(), liveStage: liveStage) }
                label: { barLabel("Search", "magnifyingglass") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                VodBrowseScreen(model: makeVodBrowseModel(),
                                makePlaybackModel: makeVodPlaybackModel)
            } label: { barIconLabel("Movies", "film") }
        }
        ToolbarItem(placement: .primaryAction) {
            NavigationLink {
                MyListScreen(model: makeMyListModel(), liveStage: liveStage)
            } label: { barIconLabel("My List", "bookmark") }
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

    /// A toolbar item's label. tvOS renders a bare icon (no `Label`): a plain-text
    /// button in the tvOS navigation bar washes out to an illegible bright-white
    /// capsule, and — in the two-column home — the bar re-expands a `Label` back to
    /// its title even under `.labelStyle(.iconOnly)`, truncating it ("Se…gs"). A
    /// lone `Image` has no title to expand, so the icon pill always reads crisply;
    /// the accessibility label keeps VoiceOver naming intact. iPhone / iPad keep
    /// the legible text title, so their bar is unchanged.
    @ViewBuilder func barLabel(_ title: String, _ symbol: String) -> some View {
        #if os(tvOS)
        Image(systemName: symbol).accessibilityLabel(Text(title))
        #else
        Text(title)
        #endif
    }

    /// Like ``barLabel`` but the non-tvOS bar keeps the icon+title `Label` (as the
    /// Movies / My List items always have): only these two carried an icon on
    /// iPhone / iPad, so their look there is preserved, while tvOS still gets the
    /// bare-icon pill that neither washes out nor truncates.
    @ViewBuilder func barIconLabel(_ title: String, _ symbol: String) -> some View {
        #if os(tvOS)
        barLabel(title, symbol)
        #else
        Label(title, systemImage: symbol)
        #endif
    }
}
