import Testing
@testable import Telly

/// Coverage for the per-playlist key builders and the typed `SettingsStore`
/// accessors over them — incl. the default-TRUE enabled/group-enabled behaviour
/// (an unset key reads back nil from the store, so `?? true` applies).
@MainActor
struct PlaylistSettingsKeysTests {
    private let url = "http://127.0.0.1:8000/a/playlist.m3u"

    private func store() -> SettingsStore { SettingsStore(backing: InMemoryKeyValueStore()) }

    @Test func keyFormatsMatchAndroid() {
        #expect(PlaylistSettingsKeys.updateIntervalKey(url) == "playlist_update_interval:\(url)")
        #expect(PlaylistSettingsKeys.updateOnStartKey(url) == "playlist_update_on_start:\(url)")
        #expect(PlaylistSettingsKeys.enabledKey(url) == "playlist_enabled:\(url)")
        #expect(PlaylistSettingsKeys.groupEnabledKey(url, group: "News")
            == "playlist_group_enabled:\(url):News")
    }

    @Test func intervalChoicesMatchAndroid() {
        #expect(PlaylistSettingsKeys.PLAYLIST_INTERVAL_CHOICES == [0, 1, 2, 4, 8, 12, 24])
    }

    @Test func defaultsWhenUnset() {
        let s = store()
        #expect(s.updateInterval(url: url) == 0)
        #expect(s.updateOnStart(url: url) == false)
        #expect(s.enabled(url: url) == true)
        #expect(s.groupEnabled(url: url, group: "News") == true)
    }

    @Test func writesRoundTrip() {
        let s = store()
        s.setUpdateInterval(url: url, 12)
        s.setUpdateOnStart(url: url, true)
        s.setEnabled(url: url, false)
        s.setGroupEnabled(url: url, group: "News", false)
        #expect(s.updateInterval(url: url) == 12)
        #expect(s.updateOnStart(url: url) == true)
        #expect(s.enabled(url: url) == false)
        #expect(s.groupEnabled(url: url, group: "News") == false)
    }
}
