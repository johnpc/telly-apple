import Testing
@testable import Telly

/// The pure post-playlist-update EPG-refresh decision: a refresh runs only when
/// a change actually landed AND the app-wide "Update on playlists change" toggle
/// is enabled; every other combination skips it.
struct EpgRefreshPolicyTests {
    @Test func enabledAndUpdatedRefreshes() {
        #expect(EpgRefreshPolicy.shouldRefreshAfterPlaylistUpdate(anyUpdated: true, updateOnChange: true))
    }

    @Test func disabledSkipsEvenWhenUpdated() {
        #expect(!EpgRefreshPolicy.shouldRefreshAfterPlaylistUpdate(anyUpdated: true, updateOnChange: false))
    }

    @Test func enabledButNothingUpdatedSkips() {
        #expect(!EpgRefreshPolicy.shouldRefreshAfterPlaylistUpdate(anyUpdated: false, updateOnChange: true))
    }

    @Test func disabledAndNothingUpdatedSkips() {
        #expect(!EpgRefreshPolicy.shouldRefreshAfterPlaylistUpdate(anyUpdated: false, updateOnChange: false))
    }
}
