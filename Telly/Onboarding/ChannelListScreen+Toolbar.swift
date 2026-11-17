import SwiftUI

/// The home's primary actions (Guide, History, Search, Movies, My List, the
/// Favorites / Visibility editors, Add playlist, Settings), rendered as the iOS
/// navigation-bar toolbar or the Apple TV rail from ONE item list.
extension ChannelListScreen {
    /// The home's primary actions, as one view list so the iPhone/iPad navigation
    /// bar and the Apple TV rail render the SAME items with the same destinations.
    @ViewBuilder var navigationItems: some View {
        NavigationLink { GuideStageScreen(stage: liveStage) }
            label: { barLabel("Guide", "tv") }.toolbarAccessibility("Guide")
        NavigationLink { HistoryScreen(model: makeHistoryModel(), liveStage: liveStage) }
            label: { barLabel("History", "clock.arrow.circlepath") }.toolbarAccessibility("History")
        NavigationLink { SearchScreen(model: makeSearchModel(), liveStage: liveStage) }
            label: { barLabel("Search", "magnifyingglass") }.toolbarAccessibility("Search")
        NavigationLink { VodBrowseScreen(model: makeVodBrowseModel(), makePlaybackModel: makeVodPlaybackModel) }
            label: { barIconLabel("Movies", "film") }.toolbarAccessibility("Movies")
        NavigationLink { MyListScreen(model: makeMyListModel(), liveStage: liveStage) }
            label: { barIconLabel("My List", "bookmark") }.toolbarAccessibility("My List")
        NavigationLink { ManageFavoritesScreen(model: makeChannelEditModel(nil)) }
            label: { barLabel("Favorites", "star") }.toolbarAccessibility("Favorites")
        NavigationLink { ManageVisibilityScreen(model: makeVisibilityEditModel()) }
            label: { barLabel("Visibility", "eye") }.toolbarAccessibility("Visibility")
        Button(action: onAdd) { barLabel("Add", "plus") }.toolbarAccessibility("Add")
        Button { showSettings = true } label: { barLabel("Settings", "gearshape") }.toolbarAccessibility("Settings")
    }

    /// iPhone / iPad: the items live in the navigation bar (iOS collapses the tail
    /// into its overflow menu on compact widths). tvOS uses ``tvRail`` instead.
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) { navigationItems }
    }

    /// An item's label. tvOS: an icon-only `Label` in the app's own rail — it keeps
    /// the icon pill crisp and VoiceOver / automation get the title. (The tvOS
    /// NAVIGATION BAR is unusable for this: it re-expands icon-only Labels into
    /// truncated titles, discards accessibility labels on images or controls and
    /// speaks the SF Symbol's name instead, and its items are not reachable by
    /// pressing UP from the content — hence the rail.) iPhone / iPad keep text.
    @ViewBuilder func barLabel(_ title: String, _ symbol: String) -> some View {
        #if os(tvOS)
        Label(title, systemImage: symbol).labelStyle(.iconOnly)
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

extension View {
    /// Names a toolbar control for VoiceOver AND automation at the control level.
    /// A label on the inner `Image` alone is ignored by the tvOS toolbar, which
    /// otherwise speaks the SF Symbol's name ("tv", "movie", "Gear shape").
    func toolbarAccessibility(_ title: String) -> some View {
        accessibilityLabel(Text(title)).accessibilityIdentifier("toolbar.\(title)")
    }
}
