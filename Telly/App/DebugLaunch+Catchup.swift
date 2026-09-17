#if DEBUG
import Foundation

/// DEBUG-only catch-up / archive screenshot proof (`-tellyCatchup`), kept out of
/// the 99-line `DebugLaunch` core (the `+History`/`+Parental` precedent). Seeds a
/// single catch-up-capable fixture channel plus an already-aired programme so the
/// archive `PlaybackScreen` (with its "Catch-up" badge) can be captured on a
/// simulator — using only a fake local template URL, never the real provider.
extension DebugLaunch {
    /// Whether to route straight to the archive playback proof — set by
    /// `-tellyCatchup`.
    static func catchupDemoRequested(in args: [String]) -> Bool {
        args.contains("-tellyCatchup")
    }

    /// One `default`-type catch-up channel: a fake local archive template
    /// (`utc`/`duration` tokens, no real host), a 7-day horizon, and a tvg-id
    /// matching ``catchupEpgDocument`` so the aired programme binds to it.
    static func catchupFixturePlaylist(base: String) -> M3uPlaylist {
        M3uPlaylist(epgURL: nil, channels: [
            M3uChannel(title: "Archive HD", streamURL: base + "live.ts",
                       tvgID: demoEpgId, tvgName: nil, tvgLogo: nil, groupTitle: "Live",
                       catchup: "default",
                       catchupSource: "\(base)archive?utc=${start}&dur=${duration}",
                       catchupDays: 7),
        ])
    }

    /// A single programme that ALREADY AIRED — starting 90 min ago and ending 30
    /// min ago — so `CatchupPlayability.playable` returns true (fully past, inside
    /// the 7-day horizon) for the demo cell.
    static func catchupEpgDocument(nowMs: Int) -> XmltvDocument {
        let minute = 60_000
        return XmltvDocument(programs: [
            XmltvProgram(channelId: demoEpgId, startMs: nowMs - 90 * minute,
                         endMs: nowMs - 30 * minute,
                         details: ProgramDetails(title: "Aired Documentary")),
        ])
    }
}
#endif
