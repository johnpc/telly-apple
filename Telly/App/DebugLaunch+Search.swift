#if DEBUG
import Foundation

/// DEBUG-only launch flags + synthetic seed for the Search screenshot proof
/// (Slice 8), kept out of the 99-line `DebugLaunch` core (the `+History`/
/// `+Playlists` precedent). Seeds one `127.0.0.1:8000` playlist across a couple
/// groups, a handful of now/upcoming programmes on the two News channels, and a
/// few recent-query history entries — so the empty-query landing shows history
/// and a `news` query hits BOTH channel names and programme titles, all local,
/// never touching the real provider.
extension DebugLaunch {
    static let searchDemoPlaylistUrl = "http://127.0.0.1:8000/playlist.m3u"
    /// EPG ids of the two News channels the seed attaches now/next programmes to.
    static let searchNewsEpgId = "bbc.news"
    static let searchN24EpgId = "news24.tv"
    /// Seeded recent queries so the empty-query landing shows a populated list.
    static let searchHistorySeed = ["bbc news", "sport", "movies", "kids tv"]

    /// `-tellySearch`: open the search landing (empty query → history list).
    static func searchDemoRequested(in args: [String]) -> Bool { args.contains("-tellySearch") }
    /// `-tellySearchResults <query>`: open search with the query prefilled + run.
    static func searchResultsQuery(in args: [String]) -> String? {
        value(for: "-tellySearchResults", in: args)
    }

    /// Whether either Slice-8 search route was requested (the single branch
    /// `ContentView+Debug` checks before dispatching to `searchDebug`).
    static func searchDebugRequested(in args: [String]) -> Bool {
        searchDemoRequested(in: args) || searchResultsQuery(in: args) != nil
    }

    /// Seeds the synthetic playlist, its now/upcoming programmes and the recent-
    /// query history. Idempotent: `add` replaces by URL, `upsertReplacing` swaps
    /// per channel and the history key is overwritten, so relaunching is safe.
    static func seedSearchFixtures(playlistStore: PlaylistStore, programStore: ProgramStore,
                                   store: KeyValueStore, now: () -> Int) {
        _ = try? playlistStore.add(sourceUrl: searchDemoPlaylistUrl, playlist: searchFixture(),
                                   name: "Fixtures", nowMs: Int64(now()))
        try? programStore.upsertReplacing(document: searchEpgDocument(nowMs: now()),
                                          keepDescriptions: false)
        store.writeString(searchHistorySeed.joined(separator: "\n"), "search.history")
    }

    /// Two News channels (name-matches for `news`) plus a Sports and a Movies
    /// channel across three groups; the News channels carry EPG ids so the
    /// channel shelf can show a now-title + progress.
    static func searchFixture() -> M3uPlaylist {
        M3uPlaylist(epgURL: nil, channels: [
            searchChannel("BBC News", "News", "bbcnews.ts", searchNewsEpgId),
            searchChannel("News 24", "News", "news24.ts", searchN24EpgId),
            searchChannel("Sky Sports", "Sports", "sports.ts", "sports.tv"),
            searchChannel("Cinema One", "Movies", "movies.ts", "movies.tv"),
        ])
    }

    /// "News at Ten" airing NOW on BBC News (channel-shelf now-title + progress
    /// and a live master-lane row), "Newsnight Special" next, and "News Bulletin"
    /// now on News 24 — all word-prefix matches for `news`, all `endMs > now`.
    static func searchEpgDocument(nowMs: Int) -> XmltvDocument {
        let half = 30 * 60_000
        return XmltvDocument(programs: [
            XmltvProgram(channelId: searchNewsEpgId, startMs: nowMs - half, endMs: nowMs + half,
                         details: ProgramDetails(title: "News at Ten")),
            XmltvProgram(channelId: searchNewsEpgId, startMs: nowMs + half, endMs: nowMs + 3 * half,
                         details: ProgramDetails(title: "Newsnight Special")),
            XmltvProgram(channelId: searchN24EpgId, startMs: nowMs - half, endMs: nowMs + half,
                         details: ProgramDetails(title: "News Bulletin")),
        ])
    }

    private static func searchChannel(_ title: String, _ group: String, _ file: String,
                                      _ tvgID: String) -> M3uChannel {
        M3uChannel(title: title, streamURL: "http://127.0.0.1:8000/\(file)", tvgID: tvgID,
                   tvgName: nil, tvgLogo: nil, groupTitle: group, catchup: nil,
                   catchupSource: nil, catchupDays: nil)
    }
}
#endif
