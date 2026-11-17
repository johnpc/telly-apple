import Testing
import Foundation
@testable import Telly

/// The built-in demo provider: its playlist text round-trips through the real
/// M3U parser, advertises the in-process guide, and is what the fetch seam serves
/// for the demo URL — and nothing else.
struct DemoContentTests {
    @Test func playlistTextParsesIntoTheDemoPlan() {
        let playlist = M3uParser.parse(DemoContent.m3u)
        #expect(playlist.epgURL == DemoContent.epgUrl)
        #expect(playlist.channels.count == 11)
        #expect(playlist.channels.first?.title == "News One")
        #expect(playlist.channels.first?.tvgID == "news-one-1.demo")
        #expect(Set(playlist.channels.compactMap(\.groupTitle))
                == ["News", "Sports", "Movies", "Kids", "Music", "Demo Films"])
        #expect(playlist.channels.allSatisfy { $0.streamURL.hasPrefix("https://") || $0.streamURL == DemoContent.clipUrl })
        #expect(DemoContent.channels == playlist.channels)
    }

    @Test func liveChannelsAreTheOnesWithAGuideIdAndVodFilesAreMovies() {
        #expect(DemoContent.liveChannels.count == 7)
        #expect(DemoContent.liveChannels.allSatisfy { $0.tvgID != nil && !VodClassifier.isVod($0.streamURL) })
        let vod = DemoContent.channels.filter { $0.tvgID == nil }
        #expect(vod.map(\.title) == ["Test Pattern (offline)", "Big Buck Bunny", "Sintel", "Jellyfish"])
        #expect(vod.allSatisfy { VodClassifier.isVod($0.streamURL) })
    }

    @Test func fetchSeamServesOnlyTheDemoUrl() async throws {
        #expect(DemoContent.playlistText(for: DemoContent.playlistUrl) == DemoContent.m3u)
        #expect(DemoContent.playlistText(for: "http://example/playlist.m3u") == nil)
        #expect(try await HttpPlaylistFetcher.fetch(DemoContent.playlistUrl) == DemoContent.m3u)
        #expect(DemoContent.isEpgUrl(DemoContent.epgUrl))
        #expect(!DemoContent.isEpgUrl("http://example/epg.xml"))
    }

    @Test func movieHouseOffersCatchUpAndTheBundledClipResolvesToAFile() {
        let movieHouse = DemoContent.channels.first { $0.title == "Movie House" }
        #expect(movieHouse?.catchup == "default")
        #expect(movieHouse?.catchupDays == 3)   // covers all of "Yesterday" even at 23:59
        #expect(movieHouse?.catchupSource?.contains("{utc}") == true)
        let resolved = DemoContent.playableUrl(for: DemoContent.clipUrl, bundle: Bundle(for: AppEnvironment.self))
        #expect(resolved.hasPrefix("file://") && resolved.hasSuffix("demo-clip.mp4"))
        #expect(DemoContent.playableUrl(for: "https://x/y.m3u8") == "https://x/y.m3u8")
        #expect(DemoContent.playableUrl(for: DemoContent.clipUrl, bundle: Bundle(for: AppEnvironment.self)) != DemoContent.clipUrl)
    }

    @Test func demoUrlIsNotMistakenForAnXtreamAccount() {
        #expect(!XtreamCredentials.isApiUrl(DemoContent.playlistUrl))
        #expect(!HttpUrl.isValid(DemoContent.playlistUrl))  // never enters the wizard's http-only path
    }
}
