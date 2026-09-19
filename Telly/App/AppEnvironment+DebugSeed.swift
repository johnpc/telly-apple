#if DEBUG
import Foundation

/// DEBUG-only real-provider seed: fetches + imports the live playlist/EPG named
/// by the process environment through the SAME path the add-playlist wizard uses
/// (`HttpPlaylistFetcher` → `M3uParser` → `PlaylistStore.add`, then the standard
/// forced EPG refresh), so a headless `simctl launch` populates real channels
/// without keyboard entry. URLs come only from the environment; `fetch` is
/// injectable so the import is testable offline against a fake fetcher.
extension AppEnvironment {
    /// Imports `seed` and republishes the feed: fetch+parse the M3U, attach the
    /// optional EPG URL, persist via the shared store, then force an EPG refresh
    /// (which fetches the attached source) and reload the channel list.
    func seedRealPlaylist(_ seed: DebugSeedPlaylist,
                          fetch: (String) async throws -> String = HttpPlaylistFetcher.fetch) async {
        guard let text = try? await fetch(seed.playlistUrl) else { return }
        var playlist = M3uParser.parse(text)
        if let epg = seed.epgUrl { playlist.epgURL = epg }
        _ = try? playlistStore.add(sourceUrl: seed.playlistUrl, playlist: playlist,
                                   name: nil, nowMs: Int64(clock()))
        reload()
        mirrorSyncedConfig()  // a real-seed simulates a user add → write-through
        await refreshEpgNow()
        channelListModel.load()
    }

    /// Parses the seed from `environment` and imports it; a no-op when unset.
    func seedRealPlaylistIfRequested(environment: [String: String],
                                     fetch: (String) async throws -> String = HttpPlaylistFetcher.fetch) async {
        guard let seed = DebugSeedPlaylist.from(environment: environment) else { return }
        await seedRealPlaylist(seed, fetch: fetch)
    }
}
#endif
