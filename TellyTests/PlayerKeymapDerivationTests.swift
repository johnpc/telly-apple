import Testing
@testable import Telly

/// Pure derivation + choice metadata for the remappable player keys (Slice 1):
/// raw -> action coercion, out-of-range/negative fallbacks, every display title,
/// and a derived keymap flipping a `PlaybackKeyPolicy` resolution.
struct PlayerKeymapDerivationTests {
    private func command(_ overlay: PlaybackOverlay, _ key: PlaybackKey, _ keymap: PlayerKeymap) -> PlaybackCommand {
        PlaybackKeyPolicy.command(overlay: overlay, key: key, keymap: keymap)
    }

    // MARK: - raw -> action

    @Test func eachRawResolvesToItsAction() {
        let map = PlayerKeymap.from(okRaw: 1, upDownRaw: 1, leftRightRaw: 1, longOkRaw: 1)
        #expect(map.ok == .channelsList)
        #expect(map.upDown == .switchChannels)
        #expect(map.leftRight == .switchChannels)
        #expect(map.longOk == .channelsList)

        let map2 = PlayerKeymap.from(okRaw: 2, upDownRaw: 0, leftRightRaw: 0, longOkRaw: 0)
        #expect(map2.ok == .nothing)
        #expect(map2.upDown == .showInfo)
        #expect(map2.leftRight == .nothing)
        #expect(map2.longOk == .quickMenu)
    }

    @Test func defaultRawsMatchStructDefaults() {
        let derived = PlayerKeymap.from(okRaw: 0, upDownRaw: 0, leftRightRaw: 0, longOkRaw: 0)
        let defaults = PlayerKeymap()
        #expect(derived.ok == defaults.ok)
        #expect(derived.upDown == defaults.upDown)
        #expect(derived.leftRight == defaults.leftRight)
        #expect(derived.longOk == defaults.longOk)
    }

    // MARK: - out-of-range / negative -> default

    @Test func outOfRangeRawsCoerceToDefaults() {
        let map = PlayerKeymap.from(okRaw: 99, upDownRaw: 3, leftRightRaw: 2, longOkRaw: 7)
        #expect(map.ok == .showInfo)
        #expect(map.upDown == .showInfo)
        #expect(map.leftRight == .nothing)
        #expect(map.longOk == .quickMenu)
    }

    @Test func negativeRawsCoerceToDefaults() {
        let map = PlayerKeymap.from(okRaw: -1, upDownRaw: -5, leftRightRaw: -1, longOkRaw: Int.min)
        #expect(map.ok == .showInfo)
        #expect(map.upDown == .showInfo)
        #expect(map.leftRight == .nothing)
        #expect(map.longOk == .quickMenu)
    }

    // MARK: - raw value stability

    @Test func rawValuesAreStable() {
        #expect(PlayerOkAction.showInfo.rawValue == 0)
        #expect(PlayerOkAction.channelsList.rawValue == 1)
        #expect(PlayerOkAction.nothing.rawValue == 2)
        #expect(PlayerUpDownAction.showInfo.rawValue == 0)
        #expect(PlayerUpDownAction.switchChannels.rawValue == 1)
        #expect(PlayerUpDownAction.nothing.rawValue == 2)
        #expect(PlayerLeftRightAction.nothing.rawValue == 0)
        #expect(PlayerLeftRightAction.switchChannels.rawValue == 1)
        #expect(PlayerLongOkAction.quickMenu.rawValue == 0)
        #expect(PlayerLongOkAction.channelsList.rawValue == 1)
    }

    // MARK: - titles

    @Test func okTitles() {
        #expect(PlayerOkAction.showInfo.title == "Show info panel")
        #expect(PlayerOkAction.channelsList.title == "Open channels list")
        #expect(PlayerOkAction.nothing.title == "Nothing")
    }

    @Test func upDownTitles() {
        #expect(PlayerUpDownAction.showInfo.title == "Show info panel")
        #expect(PlayerUpDownAction.switchChannels.title == "Switch channels")
        #expect(PlayerUpDownAction.nothing.title == "Nothing")
    }

    @Test func leftRightTitles() {
        #expect(PlayerLeftRightAction.nothing.title == "Nothing")
        #expect(PlayerLeftRightAction.switchChannels.title == "Switch channels")
    }

    @Test func longOkTitles() {
        #expect(PlayerLongOkAction.quickMenu.title == "Open quick menu")
        #expect(PlayerLongOkAction.channelsList.title == "Open channels list")
    }

    @Test func allCasesAreEnumerable() {
        #expect(PlayerOkAction.allCases.count == 3)
        #expect(PlayerUpDownAction.allCases.count == 3)
        #expect(PlayerLeftRightAction.allCases.count == 2)
        #expect(PlayerLongOkAction.allCases.count == 2)
    }

    // MARK: - derived keymap flips a policy resolution

    @Test func derivedUpDownFlipsResolvedCommand() {
        let defaultMap = PlayerKeymap.from(okRaw: 0, upDownRaw: 0, leftRightRaw: 0, longOkRaw: 0)
        #expect(command(.none, .up, defaultMap) == .showInfo)

        let remapped = PlayerKeymap.from(
            okRaw: 0,
            upDownRaw: PlayerUpDownAction.switchChannels.rawValue,
            leftRightRaw: 0,
            longOkRaw: 0
        )
        #expect(command(.none, .up, remapped) == .zap(delta: 1))
        #expect(command(.none, .down, remapped) == .zap(delta: -1))
    }

    @Test func derivedOkAndLongOkFlipResolvedCommand() {
        let remapped = PlayerKeymap.from(
            okRaw: PlayerOkAction.channelsList.rawValue,
            upDownRaw: 0,
            leftRightRaw: 0,
            longOkRaw: PlayerLongOkAction.channelsList.rawValue
        )
        #expect(command(.none, .ok, remapped) == .openPanel)
        #expect(command(.none, .longOk, remapped) == .openPanel)
    }
}
