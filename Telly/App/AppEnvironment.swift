import Foundation

/// Composition root — the single place logic meets the wall clock, the file
/// system and the network (the Apple mirror of the Android `ServiceLocator`).
/// Views observe it for the "do we have a playlist yet?" routing decision.
@MainActor
@Observable
final class AppEnvironment {
    let playlistStore: PlaylistStore
    let channelStore: ChannelStore
    let programStore: ProgramStore
    let guideEpgStore: GuideEpgStore
    private(set) var playlists: [PlaylistEntity] = []

    init(database: AppDatabase) {
        playlistStore = PlaylistStore(db: database)
        channelStore = ChannelStore(db: database)
        programStore = ProgramStore(db: database)
        guideEpgStore = GuideEpgStore(
            channelStore: channelStore, repository: EpgRepository(store: programStore),
            now: { Int(Date().timeIntervalSince1970 * 1_000) })
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

    /// The EPG refresh orchestrator over the real downloader and wall clock.
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

    /// A live-playback orchestrator over a fresh engine and the current visible
    /// channel snapshot, wired to `UserDefaults` for last-channel persistence.
    func makeLivePlaybackModel() -> LivePlaybackModel {
        let key = "lastChannelId"
        let defaults = UserDefaults.standard
        return LivePlaybackModel(
            engine: makeEngine(),
            channels: (try? channelStore.visibleChannels()) ?? [],
            now: { Int(Date().timeIntervalSince1970 * 1_000) },
            persistLastChannel: { defaults.set($0, forKey: key) },
            loadLastChannel: { defaults.object(forKey: key) as? Int },
            onExitToGuide: {},
            nowNext: { [guideEpgStore] channel in guideEpgStore.nowNext(forEpgId: channel.epgId) })
    }
}
