import Testing
@testable import Telly

/// Pure label formatting for picker rows and quick-bar slots.
struct TrackLabelsTests {
    @Test func videoSizeWithBitrate() {
        let track = VideoTrack(id: "v", width: 1920, height: 1080, bitrate: 5_200_000)
        #expect(TrackLabels.video(track) == "1920×1080, 5.2 Mbps")
    }

    @Test func videoSizeOnlyWhenBitrateMissing() {
        let track = VideoTrack(id: "v", width: 1920, height: 1080, bitrate: 0)
        #expect(TrackLabels.video(track) == "1920×1080")
    }

    @Test func videoFallbackWhenDimensionsMissing() {
        let track = VideoTrack(id: "v", width: 0, height: 0, bitrate: 5_000_000)
        #expect(TrackLabels.video(track) == "Video")
    }

    @Test func audioLanguageAndChannels() {
        #expect(TrackLabels.audio(AudioTrack(id: "a", language: "en", channels: 2), index: 0) == "English · Stereo")
        #expect(TrackLabels.audio(AudioTrack(id: "a", language: "en", channels: 1), index: 0) == "English · Mono")
        #expect(TrackLabels.audio(AudioTrack(id: "a", language: "en", channels: 6), index: 0) == "English · Surround")
    }

    @Test func audioFallbackForUndeclaredLanguage() {
        #expect(TrackLabels.audio(AudioTrack(id: "a", language: nil, channels: 0), index: 0) == "Audio 1")
        #expect(TrackLabels.audio(AudioTrack(id: "a", language: "und", channels: 0), index: 0) == "Audio 1")
    }

    @Test func textLabelAndFallback() {
        #expect(TrackLabels.text(TextTrack(id: "t", language: "en"), index: 0) == "English")
        #expect(TrackLabels.text(TextTrack(id: "t", language: nil), index: 0) == "Subtitles 1")
    }

    @Test func syncOffsetSigns() {
        #expect(TrackLabels.sync(150) == "+150 ms")
        #expect(TrackLabels.sync(0) == "0 ms")
        #expect(TrackLabels.sync(-150) == "-150 ms")
    }

    @Test func subtitleSlotOffVersusSelected() {
        var snapshot = TrackSnapshot(texts: [TextTrack(id: "t", language: "en")])
        #expect(TrackLabels.subtitleSlot(snapshot) == "Off")
        snapshot.selectedTextId = "t"
        #expect(TrackLabels.subtitleSlot(snapshot) == "English")
    }
}
