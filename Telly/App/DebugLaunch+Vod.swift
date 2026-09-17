#if DEBUG
import Foundation

/// DEBUG-only launch flag + fixture seed for the Movies-browser screenshot proof
/// (`-tellyVodBrowse`), kept out of the 99-line `DebugLaunch` core (the
/// `+Groups`/`+History` precedent). Seeds four movies across two categories into
/// `vod_items` plus one mid-band `vod_positions` row, so the browse grid renders
/// a category column and a card carrying a "Continue watching" bar — never
/// touching the real provider.
extension DebugLaunch {
    static let vodPlaylistId = 900
    static let vodBase = "http://127.0.0.1:8000/vod/"
    /// The resume-seeded movie's key (`streamUrl|name`), 33% in so it sits in the
    /// 5–95% resume band and its card shows a Continue-watching bar.
    static let vodResumeKey = "\(vodBase)heist.mp4|The Heist"

    /// Whether to route straight to the Movies browser — set by `-tellyVodBrowse`.
    static func vodBrowseRequested(in args: [String]) -> Bool {
        args.contains("-tellyVodBrowse")
    }

    /// Seeds the fixture movies + one resume position when the flag is present.
    /// Idempotent: `replace` swaps the fixture playlist's rows and the position
    /// upserts on its key, so relaunching is safe. A no-op without the flag.
    static func seedVodIfRequested(items: VodItemStore, positions: VodPositionStore,
                                   args: [String]) {
        guard vodBrowseRequested(in: args) else { return }
        try? items.replace(playlistId: vodPlaylistId, items: vodFixture())
        try? positions.save(itemKey: vodResumeKey, positionMs: 30 * 60_000,
                            durationMs: 90 * 60_000)
    }

    /// Four movies across two categories, in playlist/sort order.
    static func vodFixture() -> [VodItem] {
        [vodItem(0, "The Heist", "Action", "heist.mp4"),
         vodItem(1, "Night Chase", "Action", "chase.mp4"),
         vodItem(2, "Silent Valley", "Drama", "valley.mp4"),
         vodItem(3, "Last Letter", "Drama", "letter.mp4")]
    }

    private static func vodItem(_ index: Int, _ name: String, _ group: String,
                                _ file: String) -> VodItem {
        let url = vodBase + file
        return VodItem(id: nil, playlistId: vodPlaylistId, sortIndex: index,
                       itemKey: VodClassifier.itemKey(streamUrl: url, name: name),
                       name: name, groupTitle: group, logoUrl: nil, streamUrl: url)
    }
}
#endif
