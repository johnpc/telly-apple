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
            channel(title: "News HD", group: "Live", file: "news.ts", base: base),
            channel(title: "Movie Time", group: "VOD", file: "movie.mp4", base: base),
            channel(title: "Dead Channel", group: "Live", file: "dead.ts", base: base),
        ])
    }

    private static func channel(title: String, group: String, file: String,
                                base: String) -> M3uChannel {
        M3uChannel(title: title, streamURL: base + file, tvgID: nil, tvgName: nil,
                   tvgLogo: nil, groupTitle: group, catchup: nil,
                   catchupSource: nil, catchupDays: nil)
    }

    private static func value(for flag: String, in args: [String]) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}
#endif
