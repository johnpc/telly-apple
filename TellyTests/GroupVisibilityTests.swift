import Testing
@testable import Telly

/// The Appearance→Groups pseudo-group visibility filter: drops Favorites /
/// All channels when toggled off, never touches real playlist groups.
struct GroupVisibilityTests {
    private let names = ["Favorites", "All channels", "Live", "VOD"]

    @Test func defaultShowsBoth() {
        #expect(GroupVisibility.standard.filter(names) == names)
    }

    @Test func hidesFavoritesWhenOff() {
        var visibility = GroupVisibility.standard
        visibility.favorites = false
        #expect(visibility.filter(names) == ["All channels", "Live", "VOD"])
    }

    @Test func hidesAllChannelsWhenOff() {
        var visibility = GroupVisibility.standard
        visibility.allChannels = false
        #expect(visibility.filter(names) == ["Favorites", "Live", "VOD"])
    }

    @Test func keepsPlaylistGroupsAlways() {
        let visibility = GroupVisibility(allChannels: false, favorites: false)
        #expect(visibility.filter(names) == ["Live", "VOD"])
    }
}
