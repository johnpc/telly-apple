import Foundation

/// The built-in demo provider's install path plus the ONE playlist-import path it
/// shares with the DEBUG real-provider seed: persist via the wizard's store
/// semantics, republish, write-through the synced config, force the EPG refresh
/// (which resolves the demo guide in-process) and re-read the channel rows.
extension AppEnvironment {
    /// Installs ``DemoContent`` as a normal playlist. Idempotent: `add` replaces
    /// by source URL, so a second tap (or a `-tellyDemo` relaunch) is harmless.
    func installDemoPlaylist() async {
        await importPlaylist(sourceUrl: DemoContent.playlistUrl,
                             playlist: M3uParser.parse(DemoContent.m3u),
                             name: DemoContent.playlistName)
    }

    /// Imports `playlist` under `sourceUrl` and republishes everything that
    /// depends on it — the same steps a wizard add + "Update EPG now" performs.
    func importPlaylist(sourceUrl: String, playlist: M3uPlaylist, name: String?) async {
        _ = try? playlistStore.add(sourceUrl: sourceUrl, playlist: playlist, name: name, nowMs: Int64(clock()))
        reload()
        mirrorSyncedConfig()  // a user-level add → write-through
        await refreshEpgNow()
        channelListModel.load()
    }
}
