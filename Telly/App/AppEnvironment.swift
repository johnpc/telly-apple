import Foundation

/// Composition root — the single place logic meets the wall clock, the file
/// system and the network (the Apple mirror of the Android `ServiceLocator`).
/// Views observe it for the "do we have a playlist yet?" routing decision.
/// The consumer factories live in `AppEnvironment+Factories`.
@MainActor
@Observable
final class AppEnvironment {
    let playlistStore: PlaylistStore
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
    /// The single, stable parental-controls store observed by the settings UI;
    /// built once here (mirroring `channelListModel`) so the enable toggle keeps
    /// its in-memory state across renders. The salted-hash PIN lives in the
    /// Keychain; the enable flag shares the settings ``KeyValueStore``.
    let parentalStore: ParentalStore
    private(set) var playlists: [PlaylistEntity] = []

    init(database: AppDatabase, settings: SettingsStore? = nil,
         now: @escaping () -> Int = { Int(Date().timeIntervalSince1970 * 1_000) }) {
        clock = now
        playlistStore = PlaylistStore(db: database)
        channelStore = ChannelStore(db: database)
        programStore = ProgramStore(db: database)
        watchHistoryStore = WatchHistoryStore(db: database)
        guideEpgStore = GuideEpgStore(
            channelStore: channelStore, repository: EpgRepository(store: programStore), now: now)
        channelListModel = ChannelListModel(store: channelStore)
        let resolvedSettings = settings ?? .standard
        self.settings = resolvedSettings
        parentalStore = ParentalStore(secret: KeychainSecretStore(), backing: resolvedSettings.backing)
        reload()
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
