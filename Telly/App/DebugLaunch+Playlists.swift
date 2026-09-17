#if DEBUG
import Foundation

/// DEBUG-only launch flags + synthetic seed for the Playlist/EPG/Settings
/// screenshot proofs (Slice 9), kept out of the 99-line `DebugLaunch` core (the
/// `+Settings`/`+Catchup` precedent). Seeds two `127.0.0.1:8000` playlists (one
/// with a `url-tvg` and a custom `epg_sources` row) across several named groups,
/// so the Playlists list / detail / EPG-sources / Manage-groups panes all render
/// populated — never touching the real provider.
extension DebugLaunch {
    /// The playlist every per-playlist pane (detail/groups/EPG) targets — the
    /// rich fixture with an auto `url-tvg`, a custom source and multiple groups.
    static let demoPlaylistUrl = "http://127.0.0.1:8000/a/playlist.m3u"

    static func playlistsDemoRequested(in args: [String]) -> Bool { args.contains("-tellyPlaylists") }
    static func playlistDetailRequested(in args: [String]) -> Bool { args.contains("-tellyPlaylistDetail") }
    static func epgSourcesRequested(in args: [String]) -> Bool { args.contains("-tellyEpgSources") }
    static func playlistGroupsRequested(in args: [String]) -> Bool { args.contains("-tellyPlaylistGroups") }
    static func backupRequested(in args: [String]) -> Bool { args.contains("-tellyBackup") }
    static func appearanceRequested(in args: [String]) -> Bool { args.contains("-tellyAppearance") }

    /// Whether any Slice-9 playlist/settings route was requested (the single
    /// branch `ContentView+Debug` checks before dispatching to the pane).
    static func playlistDebugRequested(in args: [String]) -> Bool {
        playlistsDemoRequested(in: args) || playlistDetailRequested(in: args)
            || epgSourcesRequested(in: args) || playlistGroupsRequested(in: args)
            || backupRequested(in: args) || appearanceRequested(in: args)
    }

    /// Seeds the two synthetic playlists and one custom EPG source. Idempotent:
    /// `add` replaces by URL and the source unique-index dedupes, so relaunching
    /// on the same simulator is safe.
    static func seedPlaylistFixtures(playlistStore: PlaylistStore,
                                     epgSourceStore: EpgSourceStore, now: () -> Int64) {
        _ = try? playlistStore.add(sourceUrl: demoPlaylistUrl, playlist: primaryFixture(),
                                   name: "Living Room", nowMs: now())
        _ = try? playlistStore.add(sourceUrl: "http://127.0.0.1:8000/b/playlist.m3u",
                                   playlist: secondaryFixture(), name: "Bedroom", nowMs: now())
        try? epgSourceStore.add(playlistUrl: demoPlaylistUrl,
                                url: "http://127.0.0.1:8000/a/epg-extra.xml", nowMs: now())
    }

    /// The primary fixture: an auto `url-tvg` plus channels across three groups.
    static func primaryFixture() -> M3uPlaylist {
        M3uPlaylist(epgURL: "http://127.0.0.1:8000/a/epg.xml", channels: [
            fixtureChannel("BBC News", "News", "news.ts"),
            fixtureChannel("Sky Sports", "Sports", "sports.ts"),
            fixtureChannel("Cinema One", "Movies", "movies.ts"),
        ])
    }

    /// The secondary fixture: no auto EPG, channels in two further groups.
    static func secondaryFixture() -> M3uPlaylist {
        M3uPlaylist(epgURL: nil, channels: [
            fixtureChannel("Cartoon Zone", "Kids", "kids.ts"),
            fixtureChannel("Jazz FM", "Music", "music.ts"),
        ])
    }

    private static func fixtureChannel(_ title: String, _ group: String, _ file: String) -> M3uChannel {
        M3uChannel(title: title, streamURL: "http://127.0.0.1:8000/\(file)", tvgID: nil,
                   tvgName: nil, tvgLogo: nil, groupTitle: group, catchup: nil,
                   catchupSource: nil, catchupDays: nil)
    }
}
#endif
