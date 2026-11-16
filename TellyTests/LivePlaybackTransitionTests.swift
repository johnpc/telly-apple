import Testing
@testable import Telly

/// The live stage's overlay machine as a TABLE: (starting overlay, key) → the
/// overlay afterwards, plus the session-level transitions (single ↔ multiview)
/// that the one ``LiveSession`` value makes structural. Every row is a real
/// `onKey` through the model, so the table pins the machine users feel, not the
/// policy in isolation (``PlaybackKeyPolicyTests`` covers key → command).
@MainActor
struct LivePlaybackTransitionTests {
    private func ch(_ id: Int) -> ChannelEntity {
        ChannelEntity(id: id, playlistId: 1, number: id, sortIndex: id,
                      source: ChannelSource(name: "Ch\(id)", groupTitle: "Live", streamUrl: "http://127.0.0.1/\(id).ts"))
    }

    private func model(startingAt overlay: PlaybackOverlay, exits: @escaping () -> Void = {}) -> LivePlaybackModel {
        let m = LivePlaybackModel(engine: FakePlayerEngine(), channels: [ch(1), ch(2), ch(3)],
                                  makeEngine: { FakePlayerEngine() }, now: { 0 },
                                  persistLastChannel: { _ in }, loadLastChannel: { nil }, onExitToGuide: exits)
        m.start()
        if overlay != .none { m.setOverlay(overlay) }
        return m
    }

    struct Row: Sendable { let from: PlaybackOverlay; let key: PlaybackKey; let to: PlaybackOverlay }
    static let table: [Row] = [
        Row(from: .none, key: .ok, to: .info),
        Row(from: .none, key: .up, to: .info),
        Row(from: .none, key: .menu, to: .quickBar),
        Row(from: .none, key: .longOk, to: .quickBar),
        Row(from: .none, key: .channelUp, to: .zapInfo),
        Row(from: .none, key: .left, to: .none),
        Row(from: .info, key: .up, to: .infoTransport),
        Row(from: .info, key: .down, to: .panel),
        Row(from: .info, key: .back, to: .none),
        Row(from: .info, key: .menu, to: .quickBar),
        Row(from: .infoTransport, key: .back, to: .none),
        Row(from: .infoTransport, key: .left, to: .infoTransport),
        Row(from: .infoTransport, key: .down, to: .panel),
        Row(from: .zapInfo, key: .back, to: .none),
        Row(from: .zapInfo, key: .down, to: .info),
        Row(from: .zapInfo, key: .channelDown, to: .zapInfo),
        Row(from: .quickBar, key: .back, to: .none),
        Row(from: .quickBar, key: .ok, to: .multiview),
        Row(from: .panel, key: .back, to: .none),
        Row(from: .panel, key: .ok, to: .panel),
        Row(from: .channelMenu(channelId: 1), key: .back, to: .panel),
        Row(from: .pushed(.trackPicker(.audio), back: .quickBar), key: .back, to: .quickBar),
        Row(from: .pushed(.resizePicker, back: .quickBar), key: .ok, to: .pushed(.resizePicker, back: .quickBar)),
    ]

    @Test(arguments: table)
    func keyMovesTheOverlayMachine(_ row: Row) {
        let m = model(startingAt: row.from)
        _ = m.onKey(row.key)
        #expect(m.overlay == row.to, "\(row.from) + \(row.key)")
    }

    @Test func backAtBarePlaybackLeavesToTheGuideWithoutChangingTheOverlay() {
        var exits = 0
        let m = model(startingAt: .none, exits: { exits += 1 })
        _ = m.onKey(.back)
        #expect(exits == 1 && m.overlay == .none)
    }

    @Test func multiviewIsOneSessionValueNotTwoFlags() {
        let m = model(startingAt: .quickBar)
        _ = m.onKey(.ok)                                  // quick-bar OK enters multiview
        #expect(m.overlay == .multiview && m.multiview != nil)
        m.setOverlay(.info)                               // single-mode mutators are inert in multiview
        #expect(m.overlay == .multiview)
        _ = m.onKey(.back)                                // BACK leaves multiview to bare playback
        #expect(m.overlay == .none && m.multiview == nil)
    }
}
