import Testing
@testable import Telly

/// The live orchestrator's aspect-ratio slice: opening the picker over the
/// quick-bar, applying a pick (engine + persistence + close), BACK clearing it,
/// and the persisted mode being pushed to the engine on start and channel tune.
@MainActor
struct LivePlaybackModelResizeTests {
    private func ch(_ id: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live",
                                            streamUrl: "http://127.0.0.1/\(id).ts"))
    }

    private func makeModel(_ engine: FakePlayerEngine, mode: ResizeMode = .fit,
                           persist: @escaping (ResizeMode) -> Void = { _ in }) -> LivePlaybackModel {
        LivePlaybackModel(
            engine: engine, channels: [ch(10), ch(20)],
            now: { 0 }, persistLastChannel: { _ in }, loadLastChannel: { nil },
            onExitToGuide: {}, resizeMode: mode, persistResizeMode: persist)
    }

    @Test func openResizePicksPushesRowsWithoutTrackPicker() {
        let model = makeModel(FakePlayerEngine())
        model.openResizePicker()
        #expect(model.resizePickerActive == true)
        #expect(model.activePicker == nil)
        #expect(model.overlay == .pushed(back: .quickBar))
        #expect(model.resizePickerRows.map(\.label) == ["Fit", "Fill", "16:9", "4:3", "Zoom"])
    }

    @Test func selectRowSetsPersistsAppliesAndCloses() {
        let engine = FakePlayerEngine()
        var persisted: [ResizeMode] = []
        let model = makeModel(engine, persist: { persisted.append($0) })
        model.openResizePicker()
        let sixteenNine = model.resizePickerRows.first { $0.label == "16:9" }
        model.selectResizeRow(sixteenNine?.id ?? "")
        #expect(model.resizeMode == .ratio16x9)
        #expect(persisted == [.ratio16x9])
        #expect(engine.resizeModes.last == .ratio16x9)
        #expect(model.overlay == .quickBar)
        #expect(model.resizePickerActive == false)
    }

    @Test func unknownRowIsIgnored() {
        let model = makeModel(FakePlayerEngine())
        model.openResizePicker()
        model.selectResizeRow("nonsense")
        #expect(model.resizeMode == .fit)
        #expect(model.overlay == .pushed(back: .quickBar))
    }

    @Test func backClearsTheResizePicker() {
        let model = makeModel(FakePlayerEngine())
        model.openResizePicker()
        #expect(model.onKey(.back) == true)
        #expect(model.overlay == .quickBar)
        #expect(model.resizePickerActive == false)
    }

    @Test func openingTrackPickerClosesTheResizePicker() {
        let model = makeModel(FakePlayerEngine())
        model.openResizePicker()
        model.openTrackPicker(.audio)
        #expect(model.resizePickerActive == false)
        #expect(model.activePicker == .audio)
    }

    @Test func startAppliesPersistedModeToEngine() {
        let engine = FakePlayerEngine()
        makeModel(engine, mode: .ratio4x3).start()
        #expect(engine.resizeModes == [.ratio4x3])
    }

    @Test func tuneReappliesModeAfterChannelLoad() {
        let engine = FakePlayerEngine()
        let model = makeModel(engine, mode: .zoom)
        model.tune(ch(20))
        #expect(engine.resizeModes.last == .zoom)
    }
}
