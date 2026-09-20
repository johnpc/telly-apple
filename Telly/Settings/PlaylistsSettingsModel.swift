import Foundation

/// The thin state core behind the Playlists management UI — the merged Apple
/// mirror of Android's playlist-extras + EPG-sources view-models. It composes the
/// existing seams (Slice-1 updater, the playlist/EPG-source stores and the
/// per-playlist settings) and keeps `playlists` published for the list. Every
/// non-trivial decision (group derivation, cascade/re-key key planning) lives in
/// the pure ``ChannelGroups`` / ``PlaylistKeyPlan`` helpers; the model just wires
/// them to I/O. Per-playlist reads/writes and EPG-source actions are in
/// `+Sources`. The add flow reuses ``AddPlaylistModel`` (never re-implemented).
@MainActor
@Observable
final class PlaylistsSettingsModel {
    private(set) var playlists: [PlaylistEntity] = []

    let playlistStore: PlaylistStore
    let epgSourceStore: EpgSourceStore
    let channelStore: ChannelStore
    let settings: SettingsStore
    let makeAddModel: () -> AddPlaylistModel
    let updater: PlaylistUpdater
    let refreshEpg: () async -> Void
    /// Republish + write-through; internal so EPG-source/add seams fire the mirror.
    let reload: () -> Void

    init(playlistStore: PlaylistStore, epgSourceStore: EpgSourceStore,
         channelStore: ChannelStore, settings: SettingsStore,
         updater: PlaylistUpdater, makeAddModel: @escaping () -> AddPlaylistModel,
         refreshEpg: @escaping () async -> Void = {},
         reload: @escaping () -> Void) {
        self.playlistStore = playlistStore
        self.epgSourceStore = epgSourceStore
        self.channelStore = channelStore
        self.settings = settings
        self.updater = updater
        self.makeAddModel = makeAddModel
        self.refreshEpg = refreshEpg
        self.reload = reload
    }

    /// Re-reads the stored playlists into the observed feed.
    func load() { playlists = (try? playlistStore.all()) ?? [] }

    /// Deletes a playlist and cascades: its channels (via the store), its custom
    /// EPG sources, and every preference key it owned.
    func delete(_ url: String) {
        let keys = PlaylistKeyPlan.allKeys(url, groups: groupNames(for: url))
        try? playlistStore.delete(sourceUrl: url)
        (try? epgSourceStore.forPlaylist(url))?.forEach { try? epgSourceStore.remove(id: $0.id) }
        keys.forEach { settings.backing.remove($0) }
        refreshed()
    }

    /// Re-targets a playlist's source URL in place (id/channels kept), migrating
    /// its EPG sources and preference keys. Returns false — changing nothing — on
    /// an invalid http(s) URL or one already taken by another playlist.
    @discardableResult
    func changeUrl(old: String, new: String) -> Bool {
        guard HttpUrl.isValid(new),
              (try? playlistStore.changeUrl(oldUrl: old, newUrl: new)) == true else { return false }
        try? epgSourceStore.rekeyPlaylist(oldUrl: old, newUrl: new)
        load()
        migrateSettings(from: old, to: new, groups: groupNames(for: new))
        reload()
        return true
    }

    private func migrateSettings(from old: String, to new: String, groups: [String]) {
        settings.setUpdateInterval(url: new, settings.updateInterval(url: old))
        settings.setUpdateOnStart(url: new, settings.updateOnStart(url: old))
        settings.setEnabled(url: new, settings.enabled(url: old))
        for group in groups {
            settings.setGroupEnabled(url: new, group: group, settings.groupEnabled(url: old, group: group))
        }
        PlaylistKeyPlan.allKeys(old, groups: groups).forEach { settings.backing.remove($0) }
    }

    func refreshed() { load(); reload() }
}
