import Foundation

/// Given the active overlay and an incoming key, decides the semantic command —
/// the pure heart of the playback overlay state machine, ported 1:1 from the
/// Android `PlaybackKeyPolicy`. Device-verified map: OK/DOWN and UP open the
/// info overlay; a second UP expands the transport row; long-OK/MENU open the
/// quick-bar; LEFT/RIGHT are inert at bare playback; CH+/CH- zap directly; BACK
/// at bare playback exits to the TV guide. The bare-playback keys route through
/// ``PlayerKeymap``, whose defaults reproduce this map exactly. A key unbound in
/// the active context yields `.nothing`.
enum PlaybackKeyPolicy {
    static func command(
        overlay: PlaybackOverlay,
        key: PlaybackKey,
        keymap: PlayerKeymap = PlayerKeymap()
    ) -> PlaybackCommand {
        resolved(overlay, key, keymap) ?? .nothing
    }

    private static func resolved(
        _ overlay: PlaybackOverlay,
        _ key: PlaybackKey,
        _ keymap: PlayerKeymap
    ) -> PlaybackCommand? {
        switch overlay {
        case .none: return atBarePlayback(key, keymap)
        case .info: return withinInfo(key, onUp: .showTransport)
        case .infoTransport: return withinTransport(key)
        case .zapInfo: return withinZap(key, keymap)
        case .channelMenu: return dismissalOnly(key, .backToPanel)
        case .pushed(let back): return dismissalOnly(key, .popTo(back))
        // Quick bar is display-only in v1: OK is the documented multiview entry
        // (until a quick-bar-selection slice lands); BACK still dismisses.
        case .quickBar: return key == .ok ? .openMultiview : dismissalOnly(key, .dismiss)
        case .panel: return dismissalOnly(key, .dismiss)
        case .multiview: return withinMultiview(key)
        }
    }

    private static func atBarePlayback(_ key: PlaybackKey, _ keymap: PlayerKeymap) -> PlaybackCommand? {
        switch key {
        case .ok: return keymap.ok.command
        case .up: return keymap.upDown.command(1)
        case .down: return keymap.upDown.command(-1)
        case .left: return keymap.leftRight.command(-1)
        case .right: return keymap.leftRight.command(1)
        case .channelUp: return .zap(delta: 1)
        case .channelDown: return .zap(delta: -1)
        case .longOk: return keymap.longOk.command
        case .menu: return .openQuickBar
        case .back: return .exitToGuide
        case .rewind, .fastForward: return nil
        }
    }

    /// The expanded transport row: OK activates the focused control, LEFT/RIGHT
    /// walk the focus across it; every other key keeps its info-overlay meaning
    /// (DOWN opens the panel, MENU the quick-bar, CH± zap, BACK dismisses).
    private static func withinTransport(_ key: PlaybackKey) -> PlaybackCommand? {
        switch key {
        case .ok: return .activateTransport
        case .left: return .moveTransportFocus(-1)
        case .right: return .moveTransportFocus(1)
        default: return withinInfo(key, onUp: nil)
        }
    }

    private static func withinInfo(_ key: PlaybackKey, onUp: PlaybackCommand?) -> PlaybackCommand? {
        switch key {
        case .back: return .dismiss
        case .up: return onUp
        case .down: return .openPanel
        case .longOk, .menu: return .openQuickBar
        case .channelUp: return .zap(delta: 1)
        case .channelDown: return .zap(delta: -1)
        default: return nil
        }
    }

    private static func withinZap(_ key: PlaybackKey, _ keymap: PlayerKeymap) -> PlaybackCommand? {
        switch key {
        case .ok: return keymap.ok.command ?? .showInfo
        case .up: return keymap.upDown.command(1) ?? .showInfo
        case .down: return keymap.upDown.command(-1) ?? .showInfo
        case .left: return keymap.leftRight.command(-1)
        case .right: return keymap.leftRight.command(1)
        case .longOk: return keymap.longOk.command
        default: return withinInfo(key, onUp: nil)
        }
    }

    private static func dismissalOnly(_ key: PlaybackKey, _ onBack: PlaybackCommand) -> PlaybackCommand? {
        key == .back ? onBack : nil
    }
}
