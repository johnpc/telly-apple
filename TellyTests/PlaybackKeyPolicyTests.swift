import Testing
@testable import Telly

/// Exhaustive (overlay, key) -> command table for the DEFAULT keymap. Every
/// `PlaybackOverlay`, `PlaybackKey` and `PlaybackCommand` case is exercised here
/// (keymap-driven variants live in `PlayerKeymapTests`).
struct PlaybackKeyPolicyTests {
    struct Row: Sendable {
        let overlay: PlaybackOverlay
        let key: PlaybackKey
        let expected: PlaybackCommand
    }

    static let rows: [Row] = bare + info + transport + zap + dismissal + multiview

    @Test(arguments: rows)
    func policyMapsKeyToCommand(_ row: Row) {
        #expect(PlaybackKeyPolicy.command(overlay: row.overlay, key: row.key) == row.expected)
    }

    // MARK: - Tables (default PlayerKeymap)

    static let bare: [Row] = [
        Row(overlay: .none, key: .ok, expected: .showInfo),
        Row(overlay: .none, key: .up, expected: .showInfo),
        Row(overlay: .none, key: .down, expected: .showInfo),
        Row(overlay: .none, key: .left, expected: .nothing),
        Row(overlay: .none, key: .right, expected: .nothing),
        Row(overlay: .none, key: .channelUp, expected: .zap(delta: 1)),
        Row(overlay: .none, key: .channelDown, expected: .zap(delta: -1)),
        Row(overlay: .none, key: .longOk, expected: .openQuickBar),
        Row(overlay: .none, key: .menu, expected: .openQuickBar),
        Row(overlay: .none, key: .back, expected: .exitToGuide),
        Row(overlay: .none, key: .rewind, expected: .nothing),
        Row(overlay: .none, key: .fastForward, expected: .nothing),
    ]

    static let info: [Row] = [
        Row(overlay: .info, key: .back, expected: .dismiss),
        Row(overlay: .info, key: .up, expected: .showTransport),
        Row(overlay: .info, key: .down, expected: .openPanel),
        Row(overlay: .info, key: .longOk, expected: .openQuickBar),
        Row(overlay: .info, key: .menu, expected: .openQuickBar),
        Row(overlay: .info, key: .channelUp, expected: .zap(delta: 1)),
        Row(overlay: .info, key: .channelDown, expected: .zap(delta: -1)),
        Row(overlay: .info, key: .ok, expected: .nothing),
        Row(overlay: .info, key: .left, expected: .nothing),
    ]

    static let transport: [Row] = [
        Row(overlay: .infoTransport, key: .up, expected: .nothing),
        Row(overlay: .infoTransport, key: .back, expected: .dismiss),
        Row(overlay: .infoTransport, key: .down, expected: .openPanel),
    ]

    static let zap: [Row] = [
        Row(overlay: .zapInfo, key: .ok, expected: .showInfo),
        Row(overlay: .zapInfo, key: .up, expected: .showInfo),
        Row(overlay: .zapInfo, key: .down, expected: .showInfo),
        Row(overlay: .zapInfo, key: .left, expected: .nothing),
        Row(overlay: .zapInfo, key: .right, expected: .nothing),
        Row(overlay: .zapInfo, key: .longOk, expected: .openQuickBar),
        Row(overlay: .zapInfo, key: .back, expected: .dismiss),
        Row(overlay: .zapInfo, key: .menu, expected: .openQuickBar),
        Row(overlay: .zapInfo, key: .channelUp, expected: .zap(delta: 1)),
        Row(overlay: .zapInfo, key: .channelDown, expected: .zap(delta: -1)),
    ]

    static let dismissal: [Row] = [
        Row(overlay: .channelMenu(channelId: 7), key: .back, expected: .backToPanel),
        Row(overlay: .channelMenu(channelId: 7), key: .ok, expected: .nothing),
        Row(overlay: .pushed(back: .panel), key: .back, expected: .popTo(.panel)),
        Row(overlay: .pushed(back: .panel), key: .ok, expected: .nothing),
        Row(overlay: .quickBar, key: .back, expected: .dismiss),
        // Quick bar is display-only in v1 → OK is the documented multiview entry.
        Row(overlay: .quickBar, key: .ok, expected: .openMultiview),
        Row(overlay: .panel, key: .back, expected: .dismiss),
        Row(overlay: .panel, key: .ok, expected: .nothing),
    ]

    static let multiview: [Row] = [
        Row(overlay: .multiview, key: .up, expected: .moveMultiviewActive(.up)),
        Row(overlay: .multiview, key: .down, expected: .moveMultiviewActive(.down)),
        Row(overlay: .multiview, key: .left, expected: .moveMultiviewActive(.left)),
        Row(overlay: .multiview, key: .right, expected: .moveMultiviewActive(.right)),
        Row(overlay: .multiview, key: .ok, expected: .promoteMultiviewActive),
        Row(overlay: .multiview, key: .back, expected: .exitMultiview),
        Row(overlay: .multiview, key: .menu, expected: .exitMultiview),
        Row(overlay: .multiview, key: .channelUp, expected: .nothing),
        Row(overlay: .multiview, key: .longOk, expected: .nothing),
    ]
}
