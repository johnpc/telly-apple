#if DEBUG
import Foundation

/// DEBUG-only synthetic guide-EPG seeding for the grid screenshot proof. Anchors
/// back-to-back programmes to the sim's wall clock so the now-line falls inside a
/// real titled cell, and never references the real provider EPG. Split from
/// `DebugLaunch` to keep each file within the source-line budget.
extension DebugLaunch {
    /// Whether to route straight to the guide grid (`GuideGridScreen`) on launch
    /// with a seeded synthetic EPG — set by `-tellyGuide`.
    static func forcedGuide(in args: [String]) -> Bool {
        args.contains("-tellyGuide")
    }

    /// Whether to pin the multiview overlay open over live playback with an
    /// engine-free session (fake colour+name tiles, nothing decoded) — set by
    /// `-tellyOverlay multiview`, the deterministic multiview screenshot proof.
    static func forcedMultiviewOverlay(in args: [String]) -> Bool {
        value(for: "-tellyOverlay", in: args) == "multiview"
    }

    /// Seeds the synthetic guide EPG (`guideEpgDocument`) so the grid renders real
    /// titled cells with the now-line inside one. A no-op unless `-tellyGuide` is
    /// set; never touches the real provider EPG.
    static func seedGuideEpg(into store: ProgramStore, args: [String], now: () -> Int) {
        guard forcedGuide(in: args) else { return }
        try? store.upsertReplacing(document: guideEpgDocument(nowMs: now()),
                                   keepDescriptions: false)
    }

    /// Back-to-back 30-min programmes on the first two fixture channels, anchored
    /// one column before `nowMs`'s half-hour floor so "now" lands inside the
    /// second (titled) cell of each strip; the third channel is left dataless.
    static func guideEpgDocument(nowMs: Int) -> XmltvDocument {
        let start = GuideGeometry.halfHourFloor(nowMs, timeZone: .current) - GuideGeometry.halfHourMs
        return XmltvDocument(programs:
            guideStrip(channelId: demoEpgId, from: start,
                       titles: ["Morning News", "Midday Report", "Evening News", "Night Desk"])
            + guideStrip(channelId: moviesEpgId, from: start,
                         titles: ["Feature Film", "Short Reel", "Cinema Classics", "Late Movie"]))
    }

    /// Adds one channel whose name overflows the guide's fixed column, so the
    /// name-marquee (scroll-on-focus/hover) can be recorded. Its own source URL
    /// keeps re-add safe; a no-op unless `-tellyGuideLongName` is set.
    static func seedLongNameChannel(into store: PlaylistStore, base: String,
                                    args: [String], now: () -> Int64) {
        guard args.contains("-tellyGuideLongName") else { return }
        _ = try? store.add(sourceUrl: base + "longname.m3u",
                           playlist: M3uPlaylist(epgURL: nil, channels: [
                               channel(title: "Ultra HD Premium Sports Network International 4K",
                                       group: "Live", file: "long.ts", base: base)]),
                           name: "LongName", nowMs: now())
    }

    private static func guideStrip(channelId: String, from start: Int,
                                   titles: [String]) -> [XmltvProgram] {
        let half = GuideGeometry.halfHourMs
        return titles.enumerated().map { index, title in
            XmltvProgram(channelId: channelId, startMs: start + index * half,
                         endMs: start + (index + 1) * half,
                         details: ProgramDetails(title: title))
        }
    }
}
#endif
