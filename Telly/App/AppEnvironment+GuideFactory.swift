import Foundation

/// The guide grid factory, split out so ``AppEnvironment+Factories`` stays within
/// its source-line budget. Besides building the model it wires the grid's load
/// seam to the forced EPG refresh, so an empty grid can offer Retry and a stale
/// one can be re-fetched — the same reload path the "Update EPG now" action uses.
extension AppEnvironment {
    /// The guide grid's observable state over the current channel + programme
    /// stores and wall clock; the clock format follows the 24-hour setting.
    func makeGuideGridModel() -> GuideGridModel {
        let model = GuideGridModel(channelStore: channelStore,
                                   repository: EpgRepository(store: programStore),
                                   now: { Int(Date().timeIntervalSince1970 * 1_000) },
                                   timeZone: .current, is24h: settings.use24hClock)
        model.refresh = { [weak self, weak model] in
            await self?.refreshEpgNow()
            model?.load()
        }
        model.myListStore = myListStore()
        return model
    }
}
