import Testing
@testable import Telly

/// The remappable bare-playback keys and the zap-overlay fallback. Covers every
/// `PlayerOkAction` / `PlayerUpDownAction` / `PlayerLeftRightAction` /
/// `PlayerLongOkAction` branch that the default keymap does not already hit.
struct PlayerKeymapTests {
    private func command(_ overlay: PlaybackOverlay, _ key: PlaybackKey, _ keymap: PlayerKeymap) -> PlaybackCommand {
        PlaybackKeyPolicy.command(overlay: overlay, key: key, keymap: keymap)
    }

    @Test func okRemapsToChannelsListOrNothing() {
        var map = PlayerKeymap(); map.ok = .channelsList
        #expect(command(.none, .ok, map) == .openPanel)
        map.ok = .nothing
        #expect(command(.none, .ok, map) == .nothing)
    }

    @Test func upDownRemapToSwitchChannelsOrNothing() {
        var map = PlayerKeymap(); map.upDown = .switchChannels
        #expect(command(.none, .up, map) == .zap(delta: 1))
        #expect(command(.none, .down, map) == .zap(delta: -1))
        map.upDown = .nothing
        #expect(command(.none, .up, map) == .nothing)
    }

    @Test func leftRightRemapToSwitchChannels() {
        var map = PlayerKeymap(); map.leftRight = .switchChannels
        #expect(command(.none, .left, map) == .zap(delta: -1))
        #expect(command(.none, .right, map) == .zap(delta: 1))
        #expect(command(.zapInfo, .left, map) == .zap(delta: -1))
        #expect(command(.zapInfo, .right, map) == .zap(delta: 1))
    }

    @Test func longOkRemapsToChannelsList() {
        var map = PlayerKeymap(); map.longOk = .channelsList
        #expect(command(.none, .longOk, map) == .openPanel)
        #expect(command(.zapInfo, .longOk, map) == .openPanel)
    }

    /// An unbound info key in the zap overlay falls back to promoting to info.
    @Test func zapOverlayFallsBackToShowInfoWhenUnbound() {
        var map = PlayerKeymap(); map.ok = .nothing; map.upDown = .nothing
        #expect(command(.zapInfo, .ok, map) == .showInfo)
        #expect(command(.zapInfo, .up, map) == .showInfo)
        #expect(command(.zapInfo, .down, map) == .showInfo)
    }

    /// The action -> command mappings are also exercised directly.
    @Test func actionCommandMappings() {
        #expect(PlayerOkAction.channelsList.command == .openPanel)
        #expect(PlayerUpDownAction.switchChannels.command(1) == .zap(delta: 1))
        #expect(PlayerLeftRightAction.switchChannels.command(-1) == .zap(delta: -1))
        #expect(PlayerLongOkAction.quickMenu.command == .openQuickBar)
    }
}
