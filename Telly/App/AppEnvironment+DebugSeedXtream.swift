#if DEBUG
import Foundation

/// DEBUG-only Xtream seed: imports the account named by the process environment
/// through the SAME path the add-playlist wizard uses (``XtreamClient`` →
/// ``PlaylistStore/add`` under the `apiUrl`, then the standard forced EPG
/// refresh), so a headless `simctl launch` populates real channels without
/// keyboard entry. Credentials come only from the environment; `fetch` is
/// injectable so the import is testable offline against a fake fetcher.
extension AppEnvironment {
    /// Imports `creds` and republishes: client import, persist via the shared
    /// store under the Xtream identity, mirror the add, force an EPG refresh
    /// (fetching the auto-attached `xmltv.php`), then reload the channel list.
    func seedXtream(_ creds: XtreamCredentials,
                    fetch: @escaping (String) async throws -> String = HttpPlaylistFetcher.fetch) async {
        guard let playlist = try? await XtreamClient(fetch: fetch).importPlaylist(creds) else { return }
        _ = try? playlistStore.add(sourceUrl: creds.apiUrl, playlist: playlist,
                                   name: nil, nowMs: Int64(clock()))
        reload()
        mirrorSyncedConfig()
        await refreshEpgNow()
        channelListModel.load()
    }

    /// Parses the seed from `environment` and imports it; a no-op when unset.
    func seedXtreamIfRequested(environment: [String: String],
                               fetch: @escaping (String) async throws -> String = HttpPlaylistFetcher.fetch) async {
        guard let creds = DebugSeedXtream.from(environment: environment)?.credentials else { return }
        await seedXtream(creds, fetch: fetch)
    }
}
#endif
