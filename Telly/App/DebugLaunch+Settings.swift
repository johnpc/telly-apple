#if DEBUG
import Foundation

/// DEBUG-only launch flag routing straight to the settings form for the
/// screenshot proof (`-tellySettings`), never touching the real provider.
/// Kept in its own file so the 99-line `DebugLaunch` core stays untouched.
extension DebugLaunch {
    static func settingsRequested(in args: [String]) -> Bool {
        args.contains("-tellySettings")
    }

    /// Optional 24-hour-clock override for the guide proof (`-tellyClock24h
    /// false` forces 12-hour labels), or nil to leave the stored setting.
    static func clock24hOverride(in args: [String]) -> Bool? {
        value(for: "-tellyClock24h", in: args).map { $0 == "true" }
    }

    /// Optional Up/Down keymap override for the remap proof: `-tellyKeymapUpDown
    /// switch` remaps the slot to switch channels (its `PlayerUpDownAction` raw
    /// value), so pressing UP zaps instead of showing info. Any other value or an
    /// absent flag leaves the stored setting untouched (nil).
    static func keymapUpDownOverride(in args: [String]) -> Int? {
        value(for: "-tellyKeymapUpDown", in: args).flatMap {
            $0 == "switch" ? PlayerUpDownAction.switchChannels.rawValue : nil
        }
    }
}
#endif
