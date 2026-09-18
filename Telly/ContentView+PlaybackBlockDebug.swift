#if DEBUG
import SwiftUI

/// DEBUG-only fullscreen block-PIN proof for `ContentView`, split out to keep
/// `ContentView+Debug` within the source-line budget. `-tellyPlaybackBlock` seeds
/// the fixture playlist, marks its first channel blocked, seeds + enables a PIN
/// (reusing `seedParentalBlock`), then presents `LivePlaybackScreen`. The model's
/// live ``PlaybackBlockGate`` intercepts the blocked channel on `start()`, so the
/// reused ``PinChallengeSheetView`` is forced over the black stage — proving the
/// player gates a blocked channel, all without decoding any stream. The PIN goes
/// straight through the ``ParentalStore`` (Keychain) and is never logged.
extension ContentView {
    @ViewBuilder var playbackBlockDemo: some View {
        if let liveModel {
            LivePlaybackScreen(model: liveModel)
        } else {
            Color.black.ignoresSafeArea().task { preparePlaybackBlock() }
        }
    }

    func preparePlaybackBlock() {
        seedDebugFixtures()
        let pin = DebugLaunch.seedParentalPin(in: debugArgs) ?? "1234"
        DebugLaunch.seedParentalBlock(into: env.channelStore, parental: env.parentalStore, pin: pin)
        env.reload()
        liveModel = env.makeLivePlaybackModel()
    }
}
#endif
