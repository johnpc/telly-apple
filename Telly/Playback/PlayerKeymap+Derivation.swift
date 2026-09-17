import Foundation

extension PlayerKeymap {
    /// Builds a keymap from stored raw choice values, coercing any out-of-range
    /// or corrupt value back to the device-verified default (mirrors the
    /// clamp/snap idiom used elsewhere in settings). The `from(settings:)`
    /// adapter that supplies these raws from `SettingsStore` lands with the
    /// settings slice.
    static func from(okRaw: Int, upDownRaw: Int, leftRightRaw: Int, longOkRaw: Int) -> PlayerKeymap {
        PlayerKeymap(
            ok: PlayerOkAction(rawValue: okRaw) ?? .showInfo,
            upDown: PlayerUpDownAction(rawValue: upDownRaw) ?? .showInfo,
            leftRight: PlayerLeftRightAction(rawValue: leftRightRaw) ?? .nothing,
            longOk: PlayerLongOkAction(rawValue: longOkRaw) ?? .quickMenu
        )
    }
}
