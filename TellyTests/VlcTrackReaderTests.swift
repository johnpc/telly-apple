import Testing
@testable import Telly

/// The pure VLCKit→snapshot reader: zipping parallel name/index arrays, dropping
/// the negative "Disable" sentinel, mismatched lengths, and current-index → nil.
struct VlcTrackReaderTests {
    private func snapshot(audioNames: [String] = [], audioIndexes: [Int] = [],
                          currentAudio: Int = -1, subNames: [String] = [],
                          subIndexes: [Int] = [], currentSub: Int = -1) -> TrackSnapshot {
        VlcTrackReader.snapshot(audioNames: audioNames, audioIndexes: audioIndexes,
                                currentAudio: currentAudio, subNames: subNames,
                                subIndexes: subIndexes, currentSub: currentSub)
    }

    @Test func emptyArraysYieldEmptySnapshot() {
        let result = snapshot()
        #expect(result.audios.isEmpty)
        #expect(result.texts.isEmpty)
        #expect(result.selectedAudioId == nil)
        #expect(result.selectedTextId == nil)
    }

    @Test func singleAudioTrackMapsNameAndIndex() {
        let result = snapshot(audioNames: ["English"], audioIndexes: [0], currentAudio: 0)
        #expect(result.audios == [AudioTrack(id: "0", language: "English", channels: 0)])
        #expect(result.selectedAudioId == "0")
    }

    @Test func manyAudioTracksPreserveOrderAndSelection() {
        let result = snapshot(audioNames: ["en", "es", "fr"], audioIndexes: [1, 2, 3], currentAudio: 2)
        #expect(result.audios.map(\.id) == ["1", "2", "3"])
        #expect(result.audios.map(\.language) == ["en", "es", "fr"])
        #expect(result.selectedAudioId == "2")
    }

    @Test func disableSentinelIsFilteredByNegativeIndex() {
        let result = snapshot(audioNames: ["Disable", "English"], audioIndexes: [-1, 0], currentAudio: 0,
                              subNames: ["Disable", "English"], subIndexes: [-1, 1], currentSub: -1)
        #expect(result.audios.map(\.id) == ["0"])
        #expect(result.audios.map(\.language) == ["English"])
        #expect(result.texts.map(\.id) == ["1"])
    }

    @Test func currentIndexMinusOneMeansNoSelection() {
        let result = snapshot(audioNames: ["English"], audioIndexes: [0], currentAudio: -1,
                              subNames: ["English"], subIndexes: [2], currentSub: -1)
        #expect(result.selectedAudioId == nil)
        #expect(result.selectedTextId == nil)
    }

    @Test func mismatchedLengthsTruncateToShorter() {
        let result = snapshot(audioNames: ["a", "b", "c"], audioIndexes: [0, 1])
        #expect(result.audios.map(\.id) == ["0", "1"])
        #expect(result.audios.map(\.language) == ["a", "b"])
    }

    @Test func moreIndexesThanNamesTruncatesToNames() {
        let result = snapshot(audioNames: ["a"], audioIndexes: [0, 1, 2])
        #expect(result.audios.count == 1)
        #expect(result.audios[0].language == "a")
    }

    @Test func subtitleTracksMapIndependentlyOfAudio() {
        let result = snapshot(subNames: ["English", "Spanish"], subIndexes: [3, 4], currentSub: 4)
        #expect(result.texts == [TextTrack(id: "3", language: "English"),
                                 TextTrack(id: "4", language: "Spanish")])
        #expect(result.selectedTextId == "4")
    }

    @Test func collidingNamesStayDistinctByIndex() {
        let result = snapshot(audioNames: ["Audio", "Audio"], audioIndexes: [5, 6])
        #expect(result.audios.map(\.id) == ["5", "6"])
    }
}
