import Testing
@testable import Telly

/// Info-overlay badge derivation from the decoded stream shape.
struct PlaybackBadgesTests {
    @Test func nilVideoYieldsNoBadges() {
        #expect(PlaybackBadges.badges(nil) == [])
    }

    @Test func hdFixtureYieldsTierFpsAndAudio() {
        let video = VideoDetails(width: 1280, height: 720, frameRate: 25, audioChannels: 1)
        #expect(PlaybackBadges.badges(video) == ["HD", "25 FPS", "MONO"])
    }

    @Test func resolutionTiersMapByHeight() {
        #expect(PlaybackBadges.badges(fixture(height: 2160)).first == "UHD")
        #expect(PlaybackBadges.badges(fixture(height: 1080)).first == "FHD")
        #expect(PlaybackBadges.badges(fixture(height: 720)).first == "HD")
        #expect(PlaybackBadges.badges(fixture(height: 480)).first == "SD")
    }

    @Test func stereoAndSurroundAudioBadges() {
        #expect(PlaybackBadges.badges(fixture(channels: 2)).last == "STEREO")
        #expect(PlaybackBadges.badges(fixture(channels: 6)).last == "SURROUND")
    }

    @Test func unknownValuesDropTheirBadge() {
        let video = VideoDetails(width: 0, height: 0, frameRate: 0, audioChannels: 0)
        #expect(PlaybackBadges.badges(video) == [])
    }

    private func fixture(height: Int = 1080, channels: Int = 2) -> VideoDetails {
        VideoDetails(width: 1920, height: height, frameRate: 30, audioChannels: channels)
    }
}
