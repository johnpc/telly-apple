import Foundation

/// Composition root — the single place logic meets the wall clock, the file
/// system and the network (the Apple mirror of the Android `ServiceLocator`).
/// Views observe it for the "do we have a playlist yet?" routing decision.
/// The consumer factories live in `AppEnvironment+Factories`.
@MainActor
@Observable
final class AppEnvironment {
    let playlistStore: PlaylistStore
    let epgSourceStore: EpgSourceStore
    let channelStore: ChannelStore
    let programStore: ProgramStore
    let watchHistoryStore: WatchHistoryStore
    let guideEpgStore: GuideEpgStore
    /// The single wall-clock seam (ms since epoch) shared by the stores/factories
    /// that need a timestamp; injectable so wiring tests advance time by hand.
    let clock: () -> Int
    /// The single, stable channel-list state observed by `ChannelListScreen`.
    let channelListModel: ChannelListModel
    /// Injected scalar preferences (24-h clock, panel timeout, EPG cadence).
    let settings: SettingsStore
    /// Cross-reinstall / cross-device provider config, in the synchronizable
    /// Keychain (rides iCloud Keychain — no new entitlement). Tests inject an
    /// in-memory fake.
    @ObservationIgnored let syncedConfigStore: SyncedConfigStore
    private(set) var playlists: [PlaylistEntity] = []

    init(database: AppDatabase, settings: SettingsStore? = nil,
         syncedConfig: SyncedConfigStore? = nil,
         now: @escaping () -> Int = { Int(Date().timeIntervalSince1970 * 1_000) }) {
        clock = now
        syncedConfigStore = syncedConfig ?? KeychainSyncedConfigStore()
        playlistStore = PlaylistStore(db: database)
        epgSourceStore = EpgSourceStore(db: database)
        channelStore = ChannelStore(db: database)
        programStore = ProgramStore(db: database)
        watchHistoryStore = WatchHistoryStore(db: database)
        let resolvedSettings = settings ?? .standard
        self.settings = resolvedSettings
        // One shared group-filter closure both feeds route through, so the
        // wiring lives in a single place (the duplication gate flags copies).
        let groupFilter: ([ChannelEntity]) -> [ChannelEntity] = { [playlistStore] channels in
            AppEnvironment.groupFiltered(channels, playlistStore: playlistStore, settings: resolvedSettings)
        }
        guideEpgStore = GuideEpgStore(
            channelStore: channelStore, repository: EpgRepository(store: programStore),
            now: now, filter: groupFilter)
        channelListModel = ChannelListModel(store: channelStore, filter: groupFilter)
        reload()
        // The channel list drives its own load lifecycle off this seam: cached
        // channels render at once while it refreshes silently, an empty store
        // shows the skeleton until it resolves. Weak to avoid a retain cycle.
        channelListModel.refresh = { [weak self] in await self?.reloadChannels() }
    }

    /// The on-device environment; falls back to in-memory if the file store
    /// cannot be opened, so the app still launches into onboarding.
    static func makeShared() -> AppEnvironment {
        let database = (try? AppDatabase.makeShared()) ?? (try? AppDatabase.makeInMemory())
        return AppEnvironment(database: database ?? forcedInMemory())
    }

    private static func forcedInMemory() -> AppDatabase {
        // makeInMemory only throws on migration failure, which is a build-time
        // programming error, not a runtime condition.
        try! AppDatabase.makeInMemory()  // swiftlint:disable:this force_try
    }

    func reload() { playlists = (try? playlistStore.all()) ?? [] }

    func makeAddPlaylistModel() -> AddPlaylistModel {
        AddPlaylistModel(fetch: HttpPlaylistFetcher.fetch, store: playlistStore,
                         now: { Int64(Date().timeIntervalSince1970 * 1000) })
    }

    /// The Manage-Favorites (group nil) / Reorder-in-group editor state.
    func makeChannelEditModel(group: String? = nil) -> ChannelEditModel {
        ChannelEditModel(store: channelStore, group: group)
    }

    /// The bulk Manage-Visibility editor state.
    func makeVisibilityEditModel() -> VisibilityEditModel { VisibilityEditModel(store: channelStore) }
}
