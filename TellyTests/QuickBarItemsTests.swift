import Testing
@testable import Telly

/// The pure quick-bar label derivation: the nine ordered slots, the live
/// resolution/audio mapping, and the caller-supplied latency/subtitles.
struct QuickBarItemsTests {
    private func video(_ w: Int, _ h: Int, audio: Int) -> VideoDetails {
        VideoDetails(width: w, height: h, frameRate: 25, audioChannels: audio)
    }

    @Test func nineSlotsInOrderWithLiveLabels() {
        let items = QuickBarItems.items(video: video(1280, 720, audio: 1))
        #expect(items.map(\.action) == QuickBarAction.allCases)
        #expect(items.map(\.label) == [
            "Search", "Channels list", "Recordings", "Multiview",
            "Picture-in-picture", "1280 × 720", "Mono", "0 ms", "Off",
        ])
    }

    @Test func stereoAndSurround() {
        #expect(QuickBarItems.items(video: video(1920, 1080, audio: 2))[6].label == "Stereo")
        #expect(QuickBarItems.items(video: video(1920, 1080, audio: 6))[6].label == "Surround")
    }

    @Test func unknownStreamFallsBackToDash() {
        let none = QuickBarItems.items(video: nil)
        #expect(none[5].label == QuickBarItems.unknown)
        #expect(none[6].label == QuickBarItems.unknown)
        let zero = QuickBarItems.items(video: video(0, 0, audio: 0))
        #expect(zero[5].label == "—")
        #expect(zero[6].label == "—")
    }

    @Test func syncAndSubtitlesFromCaller() {
        let items = QuickBarItems.items(video: nil, sync: "120 ms", subtitles: "English")
        #expect(items[7].label == "120 ms")
        #expect(items[8].label == "English")
    }

    @Test func featureLabelsMatchCaptured() {
        #expect(QuickBarAction.search.feature == "Search")
        #expect(QuickBarAction.resolution.feature == "Video track")
        #expect(QuickBarAction.audio.feature == "Audio track")
        #expect(QuickBarAction.latency.feature == "Latency")
        #expect(QuickBarAction.subtitles.feature == "Subtitles")
    }
}
