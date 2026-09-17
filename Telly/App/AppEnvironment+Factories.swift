import Foundation

/// Consumer factories split out of ``AppEnvironment`` to keep each file within
/// the source-line budget. A same-module extension reads the store's internal
/// stored properties freely and inherits its `@MainActor` isolation; the
/// `@Observable` macro tracks only the stored properties in the main type, so
/// nothing here needs to move back.
extension AppEnvironment {
    /// The EPG refresh orchestrator over the real downloader and wall clock,
    /// its cadence/retention threaded from the current settings.
    func makeEpgRefresher() -> EpgRefresher {
        EpgRefresher(playlistStore: playlistStore, programStore: programStore,
                     download: { try await EpgDownloader().download(epgUrl: $0) },
                     now: { Int(Date().timeIntervalSince1970 * 1_000) })
    }

    /// Launch hook: refresh any stale guide data, then republish the feed.
    func refreshEpgIfDue() async {
        try? await makeEpgRefresher().refreshDue()
        guideEpgStore.refresh()
    }

    /// A fresh VLC-backed playback engine per presented player.
    func makeEngine() -> VLCKitPlayerEngine { VLCKitPlayerEngine() }

    /// The guide grid's observable state over the current channel + programme
    /// stores and wall clock; the clock format follows the 24-hour setting.
    func makeGuideGridModel() -> GuideGridModel {
        GuideGridModel(channelStore: channelStore,
                       repository: EpgRepository(store: programStore),
                       now: { Int(Date().timeIntervalSince1970 * 1_000) },
                       timeZone: .current, is24h: settings.use24hClock)
    }

    /// A live-playback orchestrator over a fresh engine and the current visible
    /// channel snapshot, wired to `UserDefaults` for last-channel persistence.
    func makeLivePlaybackModel() -> LivePlaybackModel {
        let key = "lastChannelId"
        let defaults = UserDefaults.standard
        return LivePlaybackModel(
            engine: makeEngine(),
            channels: (try? channelStore.visibleChannels()) ?? [],
            makeEngine: { self.makeEngine() },
            now: { Int(Date().timeIntervalSince1970 * 1_000) },
            persistLastChannel: { defaults.set($0, forKey: key) },
            loadLastChannel: { defaults.object(forKey: key) as? Int },
            onExitToGuide: {},
            nowNext: { [guideEpgStore] channel in guideEpgStore.nowNext(forEpgId: channel.epgId) })
    }
}
