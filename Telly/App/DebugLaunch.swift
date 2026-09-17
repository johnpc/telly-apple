#if DEBUG
import Foundation

/// DEBUG-only launch-argument harness for screenshot / UI verification. Lets a
/// simulator run seed a local fixture playlist (`-tellySeedBase <baseURL>`) so
/// the app boots into the channel list, and optionally jump straight to a
/// stream (`-tellyAutoplayUrl <url>`) so the live `PlaybackScreen` can be
/// captured deterministically — all without ever touching the real provider.
/// Never compiled into release builds. Every helper takes its `args` explicitly
/// (never reaches for `ProcessInfo` itself) so the seeding logic stays pure and
/// unit-testable; the view layer passes `ProcessInfo.processInfo.arguments`.
enum DebugLaunch {
    /// The EPG id given to the first fixture channel so the info-overlay proof
    /// can seed matching now/next programmes for it.
    static let demoEpgId = "news.tv"

    /// EPG id of the second fixture channel, so the guide seed can bind a second
    /// titled row (the third fixture channel is left dataless → all-filler row).
    static let moviesEpgId = "movies.tv"

    /// Stream URL to auto-open on launch, if `-tellyAutoplayUrl <url>` was set.
    static func autoplayUrl(in args: [String]) -> String? {
        value(for: "-tellyAutoplayUrl", in: args)
    }

    /// Whether to present the live orchestrator (`LivePlaybackScreen`) on launch
    /// instead of the channel list — set by `-tellyLiveDemo`.
    static func liveDemoRequested(in args: [String]) -> Bool {
        args.contains("-tellyLiveDemo")
    }

    /// Whether to pin the compact zap overlay open for the screenshot proof —
    /// set by `-tellyOverlay zap`.
    static func forcedZapOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "zap"
    }

    /// Whether to pin the info overlay open with seeded now/next for the proof —
    /// set by `-tellyOverlay info`.
    static func forcedInfoOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "info"
    }

    /// Whether to pin the quick-bar open — set by `-tellyOverlay quickBar`.
    static func forcedQuickBarOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "quickBar"
    }

    /// Whether to pin the channel panel open — set by `-tellyOverlay panel`.
    static func forcedPanelOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "panel"
    }

    /// A synthetic now/next XMLTV fixture on ``demoEpgId``: a "now" programme
    /// centred on `nowMs` (so the progress bar sits mid-way) and the "next".
    static func infoFixtureDocument(nowMs: Int) -> XmltvDocument {
        let halfHour = 30 * 60_000
        return XmltvDocument(programs: [
            XmltvProgram(channelId: demoEpgId, startMs: nowMs - halfHour,
                         endMs: nowMs + halfHour,
                         details: ProgramDetails(title: "Evening News")),
            XmltvProgram(channelId: demoEpgId, startMs: nowMs + halfHour,
                         endMs: nowMs + 3 * halfHour,
                         details: ProgramDetails(title: "Late Documentary")),
        ])
    }

    /// Seeds the fixture playlist rooted at `-tellySeedBase <http://host:port/>`
    /// so the app lands on the channel list. Re-adds by source URL, so it is
    /// safe to relaunch. A no-op when the flag is absent.
    static func seedIfRequested(into store: PlaylistStore, args: [String], now: () -> Int64) {
        guard let base = value(for: "-tellySeedBase", in: args) else { return }
        _ = try? store.add(sourceUrl: base + "playlist.m3u",
                           playlist: fixturePlaylist(base: base),
                           name: "Fixtures", nowMs: now())
    }

    /// The deterministic three-channel fixture playlist rooted at `base`.
    static func fixturePlaylist(base: String) -> M3uPlaylist {
        M3uPlaylist(epgURL: nil, channels: [
            channel(title: "News HD", group: "Live", file: "news.ts", base: base, tvgID: demoEpgId),
            channel(title: "Movie Time", group: "VOD", file: "movie.mp4", base: base, tvgID: moviesEpgId),
            channel(title: "Dead Channel", group: "Live", file: "dead.ts", base: base, tvgID: "sports.tv"),
        ])
    }

    private static func channel(title: String, group: String, file: String,
                                base: String, tvgID: String? = nil) -> M3uChannel {
        M3uChannel(title: title, streamURL: base + file, tvgID: tvgID, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil,
                   catchupSource: nil, catchupDays: nil)
    }

    private static func value(for flag: String, in args: [String]) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}
#endif
