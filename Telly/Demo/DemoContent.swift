import Foundation

/// The built-in demo provider — Telly's "fake server". It is a playlist + guide
/// served from INSIDE the app (no network, no process) behind the same fetch
/// seams a real provider goes through, so the whole app runs end-to-end on it:
/// first-run exploration, App Store review (reviewers may not reach a private
/// provider), screenshots, and the CI acceptance tests. Channel streams are
/// Apple's public HLS reference streams and long-standing public sample files,
/// so playback also works without any private content. Ships in RELEASE.
enum DemoContent {
    /// The scheme-marked source URL the demo playlist is stored under. Refreshes
    /// resolve it through ``HttpPlaylistFetcher`` → ``playlistText(for:)``.
    static let playlistUrl = "telly://demo/playlist.m3u"
    /// The guide URL the demo playlist advertises as its `url-tvg`; refreshes
    /// resolve it through ``EpgDownloader`` → ``DemoEpg``.
    static let epgUrl = "telly://demo/epg.xml"
    static let playlistName = "Demo"

    /// Whether `url` is the demo playlist; the fetcher short-circuits on it.
    static func playlistText(for url: String) -> String? { url == playlistUrl ? m3u : nil }

    /// Whether `url` is the demo guide; the downloader short-circuits on it.
    static func isEpgUrl(_ url: String) -> Bool { url == epgUrl }

    /// The one film that needs NO network: a test-pattern clip bundled in the app
    /// (`Demo/Resources/demo-clip.mp4`), stored under a stable scheme URL so a
    /// reinstall (new container path) never strands it; resolved at play time.
    static let clipUrl = "telly://demo/clip.mp4"

    /// The URL the player should actually open for `streamUrl`: the bundled clip's
    /// file URL for ``clipUrl``, otherwise `streamUrl` unchanged. The engine's
    /// single resolve seam (Android's `resolveUrl`).
    static func playableUrl(for streamUrl: String, bundle: Bundle = .main) -> String {
        guard streamUrl == clipUrl,
              let file = bundle.url(forResource: "demo-clip", withExtension: "mp4") else { return streamUrl }
        return file.absoluteString
    }

    /// The demo channels, parsed from ``m3u`` — the one source of truth, exactly
    /// as a real fetch would see it. Five live groups (the Android e2e fixture's
    /// names) plus a small VOD shelf so the Movies browser is populated.
    static var channels: [M3uChannel] { M3uParser.parse(m3u).channels }

    /// The live channels (those with a guide id) — the ones ``DemoEpg`` schedules.
    static var liveChannels: [M3uChannel] { channels.filter { $0.tvgID != nil } }

    /// The playlist text ``playlistText(for:)`` serves (what a demo server would
    /// return). `url-tvg` points at the in-process guide.
    static let m3u = """
    #EXTM3U url-tvg="\(epgUrl)"
    #EXTINF:-1 tvg-id="news-one-1.demo" group-title="News",News One
    \(apple)bipbop_16x9/bipbop_16x9_variant.m3u8
    #EXTINF:-1 tvg-id="news-one-2.demo" group-title="News",News One HD
    \(apple)bipbop_16x9/gear4/prog_index.m3u8
    #EXTINF:-1 tvg-id="sports-arena-1.demo" group-title="Sports",Sports Arena
    \(apple)bipbop_4x3/bipbop_4x3_variant.m3u8
    #EXTINF:-1 tvg-id="sports-arena-2.demo" group-title="Sports",Sports Arena HD
    \(apple)bipbop_4x3/gear4/prog_index.m3u8
    #EXTINF:-1 tvg-id="movie-house-1.demo" group-title="Movies" catchup="default" catchup-source="https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8?utc={utc}&d={duration}" catchup-days="3",Movie House
    https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
    #EXTINF:-1 tvg-id="kids-zone-1.demo" group-title="Kids",Kids Zone
    \(apple)bipbop_16x9/gear1/prog_index.m3u8
    #EXTINF:-1 tvg-id="music-box-1.demo" group-title="Music",Music Box
    \(apple)bipbop_4x3/gear1/prog_index.m3u8
    #EXTINF:-1 group-title="Demo Films",Test Pattern (offline)
    \(clipUrl)
    #EXTINF:-1 group-title="Demo Films",Big Buck Bunny
    \(sample)bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_5MB.mp4
    #EXTINF:-1 group-title="Demo Films",Sintel
    \(sample)sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4
    #EXTINF:-1 group-title="Demo Films",Jellyfish
    \(sample)jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4

    """

    /// Apple's public HLS reference streams (bipbop), the industry's test fixture.
    private static let apple = "https://devstreaming-cdn.apple.com/videos/streaming/examples/"
    /// Public sample MP4 clips (test-videos.co.uk; Blender shorts + Jellyfish).
    /// Google's gtv-videos-bucket was rejected here: it answers 403 to VLC.
    private static let sample = "https://test-videos.co.uk/vids/"
}
