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
                     now: { Int(Date().timeIntervalSince1970 * 1_000) },
                     customSources: { [epgSourceStore] in ((try? epgSourceStore.forPlaylist($0)) ?? []).map(\.url) },
                     intervalMs: settings.epgRefreshIntervalMs, keepPastMs: settings.epgKeepPastMs)
    }

    /// Launch hook: refresh any stale guide data, then republish the feed.
    func refreshEpgIfDue() async {
        try? await makeEpgRefresher().refreshDue()
        guideEpgStore.refresh()
    }

    /// Forced EPG refresh — the "Update EPG now" action and the post-playlist
    /// -update trigger: re-fetches every source regardless of age, then
    /// republishes the guide feed so freshly-imported programmes surface.
    func refreshEpgNow() async {
        try? await makeEpgRefresher().refreshAllNow()
        guideEpgStore.refresh()
    }

    /// A fresh VLC-backed playback engine per presented player.
    func makeEngine() -> VLCKitPlayerEngine { VLCKitPlayerEngine() }

    /// The recently-watched screen's observable state over the watch-history
    /// and channel stores.
    func makeHistoryModel() -> HistoryListModel {
        HistoryListModel(store: watchHistoryStore, channelStore: channelStore)
    }

    /// The search screen's observable state over the channel/programme stores,
    /// the guide EPG for now/next, and the persisted recent-query history.
    func makeSearchModel() -> SearchModel {
        SearchModel(
            repository: SearchRepository(channelStore: channelStore, programStore: programStore,
                                         epg: EpgRepository(store: programStore)),
            history: SearchHistory(store: settings.backing,
                                   saveEnabled: { [settings] in settings.saveSearchHistory }),
            now: clock, timeZone: .current, myListStore: myListStore())
    }

    /// A live-playback orchestrator over a fresh engine and the current visible
    /// channel snapshot, wired to `UserDefaults` for last-channel persistence.
    /// `engineFactory` defaults to the real VLCKit engine; wiring tests inject a
    /// fake so the recording seam runs without the untestable device glue.
    func makeLivePlaybackModel(
        engineFactory: @escaping @MainActor () -> any PlayerEngine = { VLCKitPlayerEngine() }
    ) -> LivePlaybackModel {
        let key = "lastChannelId"
        let defaults = UserDefaults.standard
        let channels = filteredVisibleChannels()
        return LivePlaybackModel(
            engine: engineFactory(),
            channels: channels,
            makeEngine: engineFactory,
            keymap: settings.playerKeymap,
            timeouts: settings.panelTimeouts,
            now: clock,
            persistLastChannel: { [watchHistoryStore, clock] id in
                defaults.set(id, forKey: key)
                guard let channel = channels.first(where: { $0.id == id }) else { return }
                try? watchHistoryStore.record(channelKey: ChannelImporter.keyOf(channel), atMs: clock())
            },
            loadLastChannel: { defaults.object(forKey: key) as? Int },
            onExitToGuide: {},
            nowNext: { [guideEpgStore] channel in guideEpgStore.nowNext(forEpgId: channel.epgId) },
            makeSearchModel: makeSearchModel)
    }
}
