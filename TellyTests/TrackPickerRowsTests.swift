import Testing
@testable import Telly

/// Records TrackFacade calls so `apply` routing can be asserted.
private final class FakeTrackFacade: TrackFacade {
    var snapshot = TrackSnapshot()
    var audioOffsetMs = 0
    var selectedVideo: String??
    var selectedAudio: String?
    var selectedText: String??

    func selectVideo(_ id: String?) { selectedVideo = .some(id) }
    func selectAudio(_ id: String) { selectedAudio = id }
    func selectText(_ id: String?) { selectedText = .some(id) }
    func setAudioOffsetMs(_ ms: Int) { audioOffsetMs = ms }
}

struct TrackPickerRowsTests {
    @Test func videoRowsLeadWithAutoCheckedWhenNoOverride() {
        let rows = TrackPickerRows.of(.video, TrackSnapshot(videos: [VideoTrack(id: "v", width: 1920, height: 1080, bitrate: 0)]))
        #expect(rows.first == TrackPickerRow(id: "auto", label: "Auto", checked: true))
        #expect(rows.count == 2)
    }

    @Test func subtitleRowsLeadWithOff() {
        let rows = TrackPickerRows.of(.subtitles, TrackSnapshot(texts: [TextTrack(id: "t", language: "en")]))
        #expect(rows.first == TrackPickerRow(id: "off", label: "Off", checked: true))
    }

    @Test func audioRowsCheckSelected() {
        var snapshot = TrackSnapshot(audios: [AudioTrack(id: "a", language: "en", channels: 2)])
        snapshot.selectedAudioId = "a"
        let rows = TrackPickerRows.of(.audio, snapshot)
        #expect(rows == [TrackPickerRow(id: "a", label: "English · Stereo", checked: true)])
    }

    @Test func syncRowsHaveFourStepsAndReset() {
        let rows = TrackPickerRows.of(.sync, TrackSnapshot())
        #expect(rows.map(\.id) == ["sync:-50", "sync:-25", "sync:25", "sync:50", "sync:reset"])
    }

    @Test func applyReturnsFalseOnlyForSync() {
        let facade = FakeTrackFacade()
        #expect(TrackPickerRows.apply(.video, rowId: "auto", tracks: facade) == true)
        #expect(TrackPickerRows.apply(.sync, rowId: "sync:reset", tracks: facade) == false)
    }

    @Test func applyRoutesVideoAndSubtitlesNilForAutoAndOff() {
        let facade = FakeTrackFacade()
        TrackPickerRows.apply(.video, rowId: "auto", tracks: facade)
        #expect(facade.selectedVideo == .some(nil))
        TrackPickerRows.apply(.video, rowId: "v1", tracks: facade)
        #expect(facade.selectedVideo == .some("v1"))
        TrackPickerRows.apply(.subtitles, rowId: "off", tracks: facade)
        #expect(facade.selectedText == .some(nil))
        TrackPickerRows.apply(.audio, rowId: "a1", tracks: facade)
        #expect(facade.selectedAudio == "a1")
    }

    @Test func kindTitles() {
        #expect(TrackPickerKind.allCases.map(\.title) == ["Video track", "Audio track", "Audio sync", "Closed captions"])
    }

    @Test func syncUnparseableRowKeepsCurrentOffset() {
        let facade = FakeTrackFacade()
        facade.audioOffsetMs = 42
        TrackPickerRows.apply(.sync, rowId: "sync:notanumber", tracks: facade)
        #expect(facade.audioOffsetMs == 42)
    }

    @Test func syncSteppingClampsAndResets() {
        let facade = FakeTrackFacade()
        facade.audioOffsetMs = 990
        TrackPickerRows.apply(.sync, rowId: "sync:50", tracks: facade)
        #expect(facade.audioOffsetMs == 1_000)
        facade.audioOffsetMs = -990
        TrackPickerRows.apply(.sync, rowId: "sync:-50", tracks: facade)
        #expect(facade.audioOffsetMs == -1_000)
        TrackPickerRows.apply(.sync, rowId: "sync:reset", tracks: facade)
        #expect(facade.audioOffsetMs == 0)
    }
}
