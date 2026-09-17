import Testing
@testable import Telly

/// Records TrackFacade calls so the model's picker routing / apply can be
/// asserted without VLCKit; mirrors the fake in `TrackPickerRowsTests`.
private final class FakeTrackFacade: TrackFacade {
    var snapshot = TrackSnapshot()
    var audioOffsetMs = 0
    var selectedAudio: String?
    var selectedText: String??

    func selectVideo(_ id: String?) {}
    func selectAudio(_ id: String) { selectedAudio = id }
    func selectText(_ id: String?) { selectedText = .some(id) }
    func setAudioOffsetMs(_ ms: Int) { audioOffsetMs = ms }
}

/// The live orchestrator's track-picker slice: opening pickers over the
/// quick-bar, deriving rows/title from the snapshot, applying selections, the
/// sync stepper staying open, quick-bar routing, and BACK clearing the picker.
@MainActor
struct LivePlaybackModelTracksTests {
    private func makeModel(_ facade: FakeTrackFacade) -> LivePlaybackModel {
        let engine = FakePlayerEngine()
        engine.tracks = facade
        return LivePlaybackModel(
            engine: engine, channels: [],
            now: { 0 }, persistLastChannel: { _ in },
            loadLastChannel: { nil }, onExitToGuide: {})
    }

    private func snapshotFixture() -> TrackSnapshot {
        var snapshot = TrackSnapshot()
        snapshot.audios = [AudioTrack(id: "0", language: "en", channels: 2),
                           AudioTrack(id: "1", language: "es", channels: 2)]
        snapshot.texts = [TextTrack(id: "0", language: "en")]
        snapshot.selectedAudioId = "0"
        return snapshot
    }

    @Test func openAudioPushesOverQuickBar() {
        let model = makeModel(FakeTrackFacade())
        model.openTrackPicker(.audio)
        #expect(model.activePicker == .audio)
        #expect(model.overlay == .pushed(back: .quickBar))
    }

    @Test func rowsAndTitleComeFromSnapshot() {
        let facade = FakeTrackFacade()
        facade.snapshot = snapshotFixture()
        let model = makeModel(facade)
        model.openTrackPicker(.audio)
        #expect(model.pickerTitle == "Audio track")
        #expect(model.pickerRows.map(\.label) == ["English · Stereo", "Spanish · Stereo"])
        #expect(model.pickerRows.first?.checked == true)
    }

    @Test func noPickerYieldsEmptyRowsAndTitle() {
        let model = makeModel(FakeTrackFacade())
        #expect(model.pickerRows.isEmpty)
        #expect(model.pickerTitle == "")
    }

    @Test func selectAudioAppliesAndClosesToQuickBar() {
        let facade = FakeTrackFacade()
        facade.snapshot = snapshotFixture()
        let model = makeModel(facade)
        model.openTrackPicker(.audio)
        model.selectPickerRow("1")
        #expect(facade.selectedAudio == "1")
        #expect(model.overlay == .quickBar)
        #expect(model.activePicker == nil)
    }

    @Test func selectOffCaptionsTurnsTextOff() {
        let facade = FakeTrackFacade()
        facade.snapshot = snapshotFixture()
        let model = makeModel(facade)
        model.openTrackPicker(.subtitles)
        model.selectPickerRow("off")
        #expect(facade.selectedText == .some(nil))
        #expect(model.overlay == .quickBar)
    }

    @Test func syncStepStaysOpen() {
        let facade = FakeTrackFacade()
        let model = makeModel(facade)
        model.openTrackPicker(.sync)
        model.selectPickerRow("sync:25")
        #expect(facade.audioOffsetMs == 25)
        #expect(model.activePicker == .sync)
        #expect(model.overlay == .pushed(back: .quickBar))
    }

    @Test func selectRowWithoutActivePickerIsNoOp() {
        let facade = FakeTrackFacade()
        let model = makeModel(facade)
        model.selectPickerRow("0")
        #expect(facade.selectedAudio == nil)
    }

    @Test func quickBarActionRoutesToPickers() {
        let model = makeModel(FakeTrackFacade())
        model.onQuickBarAction(.audio)
        #expect(model.activePicker == .audio)
        model.onQuickBarAction(.subtitles)
        #expect(model.activePicker == .subtitles)
        model.onQuickBarAction(.latency)
        #expect(model.activePicker == .sync)
    }

    @Test func resolutionActionOpensNoPicker() {
        let model = makeModel(FakeTrackFacade())
        model.onQuickBarAction(.resolution)
        #expect(model.activePicker == nil)
    }

    @Test func backFromPickerPopsToQuickBarAndClears() {
        let model = makeModel(FakeTrackFacade())
        model.openTrackPicker(.audio)
        #expect(model.onKey(.back) == true)
        #expect(model.overlay == .quickBar)
        #expect(model.activePicker == nil)
    }

    @Test func quickBarLabelsReflectSnapshotAndOffset() {
        let facade = FakeTrackFacade()
        facade.snapshot = snapshotFixture()
        facade.audioOffsetMs = 50
        let model = makeModel(facade)
        #expect(model.quickBarSubtitles == "Off")
        #expect(model.quickBarSync == "+50 ms")
        facade.snapshot.selectedTextId = "0"
        #expect(model.quickBarSubtitles == "English")
    }
}
