import Foundation

/// Composition root — the single place logic meets the wall clock, the file
/// system and the network (the Apple mirror of the Android `ServiceLocator`).
/// Views observe it for the "do we have a playlist yet?" routing decision.
@MainActor
@Observable
final class AppEnvironment {
    let playlistStore: PlaylistStore
    let channelStore: ChannelStore
    private(set) var playlists: [PlaylistEntity] = []

    init(database: AppDatabase) {
        playlistStore = PlaylistStore(db: database)
        channelStore = ChannelStore(db: database)
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

    /// A fresh VLC-backed playback engine per presented player.
    func makeEngine() -> VLCKitPlayerEngine { VLCKitPlayerEngine() }
}
