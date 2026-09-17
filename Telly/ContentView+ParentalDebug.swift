#if DEBUG
import SwiftUI

/// DEBUG-only locked-channel challenge proof for `ContentView`, split out to keep
/// `ContentView+Debug` within the source-line budget. `-tellyParentalChallenge`
/// seeds the fixture playlist, marks its first channel blocked, seeds + enables a
/// PIN, then presents the channel list with the `PinChallengeSheetView` forced
/// open over it — proving a blocked-channel tap challenges for a PIN instead of
/// tuning a player, all without decoding any stream. Compiled out of release.
extension ContentView {
    @ViewBuilder var parentalChallengeDemo: some View {
        mainContent
            .task { prepareParentalChallenge() }
            .sheet(isPresented: .constant(true)) {
                PinChallengeSheetView { env.parentalStore.verify(pin: $0) }
            }
    }

    func prepareParentalChallenge() {
        seedDebugFixtures()
        let pin = DebugLaunch.seedParentalPin(in: debugArgs) ?? "1234"
        DebugLaunch.seedParentalBlock(into: env.channelStore, parental: env.parentalStore, pin: pin)
        env.channelListModel.load()
    }
}
#endif
