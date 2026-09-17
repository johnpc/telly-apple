import Testing
@testable import Telly

/// The pure VLCKit 4 object-track → snapshot reader: mapping string `trackId`s
/// and names into the domain track models and deriving the selected id from the
/// `isSelected` flag (nil when none is selected).
struct VlcTrackReaderTests {
    private func info(_ id: String, _ name: String, selected: Bool = false) -> VlcTrackInfo {
        VlcTrackInfo(id: id, name: name, isSelected: selected)
    }

    @Test func emptyListsYieldEmptySnapshot() {
        let result = VlcTrackReader.snapshot(audio: [], text: [])
        #expect(result.audios.isEmpty)
        #expect(result.texts.isEmpty)
        #expect(result.selectedAudioId == nil)
        #expect(result.selectedTextId == nil)
    }

    @Test func singleAudioTrackMapsIdAndName() {
        let result = VlcTrackReader.snapshot(audio: [info("a0", "English", selected: true)], text: [])
        #expect(result.audios == [AudioTrack(id: "a0", language: "English", channels: 0)])
        #expect(result.selectedAudioId == "a0")
    }

    @Test func manyAudioTracksPreserveOrderAndSelection() {
        let result = VlcTrackReader.snapshot(
            audio: [info("1", "en"), info("2", "es", selected: true), info("3", "fr")], text: [])
        #expect(result.audios.map(\.id) == ["1", "2", "3"])
        #expect(result.audios.map(\.language) == ["en", "es", "fr"])
        #expect(result.selectedAudioId == "2")
    }

    @Test func noSelectedFlagMeansNoSelection() {
        let result = VlcTrackReader.snapshot(audio: [info("a", "English")],
                                             text: [info("t", "English")])
        #expect(result.selectedAudioId == nil)
        #expect(result.selectedTextId == nil)
    }

    @Test func textTracksMapIndependentlyOfAudio() {
        let result = VlcTrackReader.snapshot(
            audio: [], text: [info("t3", "English"), info("t4", "Spanish", selected: true)])
        #expect(result.texts == [TextTrack(id: "t3", language: "English"),
                                 TextTrack(id: "t4", language: "Spanish")])
        #expect(result.selectedTextId == "t4")
    }

    @Test func collidingNamesStayDistinctById() {
        let result = VlcTrackReader.snapshot(
            audio: [info("5", "Audio"), info("6", "Audio")], text: [])
        #expect(result.audios.map(\.id) == ["5", "6"])
    }
}
