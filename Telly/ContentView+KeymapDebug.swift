#if DEBUG
import SwiftUI

/// DEBUG-only glue for the keymap-remap screenshot proof. `applyKeymapOverride…`
/// writes the Up/Down override into settings BEFORE the live model is built, so
/// the model's captured `keymap` reflects `-tellyKeymapUpDown switch`; the key
/// delivery then presses UP on the bare-playback stage once seeded, so the
/// resolved overlay (info by default, zap when remapped) proves the remap on a
/// simulator. Parsing lives in the unit-tested `DebugLaunch.keymapUpDownOverride`;
/// this stays thin glue. Skipped when a forced-`-tellyOverlay` proof owns the run.
extension ContentView {
    func applyKeymapOverrideIfRequested() {
        guard let raw = DebugLaunch.keymapUpDownOverride(in: debugArgs) else { return }
        env.settings.playerKeyUpDownRaw = raw
    }

    func deliverKeymapProofKeyIfNeeded(_ model: LivePlaybackModel) {
        guard DebugLaunch.value(for: "-tellyOverlay", in: debugArgs) == nil else { return }
        model.debugApplyKey(.up)
    }
}
#endif
