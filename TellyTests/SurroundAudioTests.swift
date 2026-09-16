import Testing
@testable import Telly

/// The "surround by default" chooser, reduced to pure data.
struct SurroundAudioTests {
    @Test func emptyAudioReturnsNil() {
        #expect(SurroundAudio.pick(audios: [], selectedId: nil) == nil)
    }

    @Test func picksTheMaxChannelIdWhenNothingSelected() {
        let audios = [
            AudioTrack(id: "stereo", language: "en", channels: 2),
            AudioTrack(id: "surround", language: "en", channels: 6),
        ]
        #expect(SurroundAudio.pick(audios: audios, selectedId: nil) == "surround")
    }

    @Test func nilWhenBestDoesNotBeatSelected() {
        let audios = [
            AudioTrack(id: "stereo", language: "en", channels: 2),
            AudioTrack(id: "surround", language: "en", channels: 6),
        ]
        #expect(SurroundAudio.pick(audios: audios, selectedId: "surround") == nil)
    }

    @Test func switchesUpWhenSelectedHasFewerChannels() {
        let audios = [
            AudioTrack(id: "stereo", language: "en", channels: 2),
            AudioTrack(id: "surround", language: "en", channels: 6),
        ]
        #expect(SurroundAudio.pick(audios: audios, selectedId: "stereo") == "surround")
    }
}
