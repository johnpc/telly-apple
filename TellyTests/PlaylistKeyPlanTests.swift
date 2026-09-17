import Testing
@testable import Telly

/// The per-playlist key planner: the scalar key set and the full set (scalars
/// plus one group-enabled key per group) a URL change migrates and a delete
/// purges. Every key is built from ``PlaylistSettingsKeys``.
struct PlaylistKeyPlanTests {
    private let url = "http://127.0.0.1:8000/a/playlist.m3u"

    @Test func scalarKeysAreIntervalOnStartEnabled() {
        #expect(PlaylistKeyPlan.scalarKeys(url) == [
            PlaylistSettingsKeys.updateIntervalKey(url),
            PlaylistSettingsKeys.updateOnStartKey(url),
            PlaylistSettingsKeys.enabledKey(url)])
    }

    @Test func allKeysAppendOneGroupKeyPerGroup() {
        let keys = PlaylistKeyPlan.allKeys(url, groups: ["News", "Movies"])
        #expect(keys == PlaylistKeyPlan.scalarKeys(url) + [
            PlaylistSettingsKeys.groupEnabledKey(url, group: "News"),
            PlaylistSettingsKeys.groupEnabledKey(url, group: "Movies")])
    }

    @Test func allKeysWithNoGroupsIsJustScalars() {
        #expect(PlaylistKeyPlan.allKeys(url, groups: []) == PlaylistKeyPlan.scalarKeys(url))
    }
}
