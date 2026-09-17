#if DEBUG
import Foundation

/// DEBUG-only launch flags + synthetic seed for the custom-groups screenshot
/// proofs (Slice 7), kept out of the 99-line `DebugLaunch` core (the
/// `+Search`/`+Playlists` precedent). Seeds one `127.0.0.1:8000` playlist across
/// three groups, a small now-airing EPG fixture (so the Assign-EPG picker has
/// ids), and two pre-created custom groups WITH membership (via
/// ``CustomGroupStore``) so Manage Groups / Copy channels / the group strip all
/// render populated — never touching the real provider.
extension DebugLaunch {
    static let groupsPlaylistUrl = "http://127.0.0.1:8000/groups.m3u"
    /// The tvg-ids the fixture channels carry (= their custom-group membership
    /// keys, since `ChannelImporter.keyOf` returns the tvg-id when present).
    static let groupsEpgIds = ["bbc.one", "bbc.news", "sky.sports", "cinema.one"]
    /// The two seeded custom groups: name → member channel keys (tvg-ids).
    static let groupsSeededGroups: [(name: String, keys: [String])] = [
        ("My Mix", ["bbc.one", "sky.sports"]),
        ("News Hub", ["bbc.news"]),
    ]
    /// The populated custom group the `-tellyGroupsStrip` payoff shot lands on.
    static let groupsStripName = "My Mix"

    static func manageGroupsRequested(in args: [String]) -> Bool { args.contains("-tellyManageGroups") }
    static func groupsStripRequested(in args: [String]) -> Bool { args.contains("-tellyGroupsStrip") }
    static func manageBlockingRequested(in args: [String]) -> Bool { args.contains("-tellyManageBlocking") }
    static func assignEpgRequested(in args: [String]) -> Bool { args.contains("-tellyAssignEpg") }
    static func copyChannelsRequested(in args: [String]) -> Bool { args.contains("-tellyCopyChannels") }
    /// The PIN to pre-seed + enable so Manage Blocking shows its PIN gate
    /// (`-tellySeedPin 1234`); nil leaves the editor unlocked.
    static func groupsSeedPin(in args: [String]) -> String? { value(for: "-tellySeedPin", in: args) }

    /// Whether any Slice-7 custom-groups route was requested (the single branch
    /// `ContentView+Debug` checks before dispatching to `groupsDebug`).
    static func groupsDebugRequested(in args: [String]) -> Bool {
        manageGroupsRequested(in: args) || groupsStripRequested(in: args)
            || manageBlockingRequested(in: args) || assignEpgRequested(in: args)
            || copyChannelsRequested(in: args)
    }

    /// Seeds the synthetic playlist + its now-airing EPG. Idempotent: `add`
    /// replaces by URL and `upsertReplacing` swaps per channel, so relaunching
    /// is safe.
    static func seedGroupsFixtures(playlistStore: PlaylistStore, programStore: ProgramStore,
                                   now: () -> Int) {
        _ = try? playlistStore.add(sourceUrl: groupsPlaylistUrl, playlist: groupsFixture(),
                                   name: "Fixtures", nowMs: Int64(now()))
        try? programStore.upsertReplacing(document: groupsEpgDocument(nowMs: now()),
                                          keepDescriptions: false)
    }

    /// Creates the two seeded custom groups WITH membership (empty-then-fill, the
    /// Android Create+Copy flow). Re-running appends fresh groups, so the
    /// screenshot recipe uninstalls the sim app between launches.
    static func seedCustomGroups(store: CustomGroupStore) {
        for group in groupsSeededGroups {
            guard let id = try? store.create(name: group.name) else { continue }
            try? store.addMembers(id: id, keys: group.keys)
        }
    }

    /// Four channels across three groups, each with a tvg-id (so membership keys
    /// are stable and the Assign-EPG picker can offer their ids).
    static func groupsFixture() -> M3uPlaylist {
        M3uPlaylist(epgURL: nil, channels: [
            groupsChannel("BBC One", "Entertainment", "bbcone.ts", "bbc.one"),
            groupsChannel("BBC News", "News", "bbcnews.ts", "bbc.news"),
            groupsChannel("Sky Sports", "Sports", "skysports.ts", "sky.sports"),
            groupsChannel("Cinema One", "Movies", "cinemaone.ts", "cinema.one"),
        ])
    }

    /// A now-airing programme on two channels so `ProgramStore.channelIds()`
    /// returns ids for the Assign-EPG picker.
    static func groupsEpgDocument(nowMs: Int) -> XmltvDocument {
        let half = 30 * 60_000
        return XmltvDocument(programs: [
            XmltvProgram(channelId: "bbc.news", startMs: nowMs - half, endMs: nowMs + half,
                         details: ProgramDetails(title: "News at Ten")),
            XmltvProgram(channelId: "bbc.one", startMs: nowMs - half, endMs: nowMs + half,
                         details: ProgramDetails(title: "Evening Show")),
        ])
    }

    private static func groupsChannel(_ title: String, _ group: String, _ file: String,
                                      _ tvgID: String) -> M3uChannel {
        M3uChannel(title: title, streamURL: "http://127.0.0.1:8000/\(file)", tvgID: tvgID,
                   tvgName: nil, tvgLogo: nil, groupTitle: group, catchup: nil,
                   catchupSource: nil, catchupDays: nil)
    }
}
#endif
