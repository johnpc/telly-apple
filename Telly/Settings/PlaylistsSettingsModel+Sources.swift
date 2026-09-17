import Foundation

/// Per-playlist reads/writes and custom-EPG-source actions for
/// ``PlaylistsSettingsModel``, split out so the core stays within budget. The
/// group list is derived from the playlist's channels (``ChannelGroups``); every
/// user-entered EPG source URL is http(s)-validated exactly like the add-playlist
/// wizard, so a malformed entry is ignored rather than persisted.
extension PlaylistsSettingsModel {
    /// The playlist's distinct group titles (its Manage-groups toggle list).
    func groupNames(for url: String) -> [String] { ChannelGroups.names(channels(for: url)) }

    /// The playlist's auto-detected `url-tvg`, shown as the "(default)" source.
    func autoEpgUrl(for url: String) -> String? { playlists.first { $0.url == url }?.epgUrl }

    private func channels(for url: String) -> [ChannelEntity] {
        guard let id = playlists.first(where: { $0.url == url })?.id else { return [] }
        return (try? channelStore.channels(playlistId: Int(id))) ?? []
    }

    // MARK: Per-playlist scalar settings

    func interval(for url: String) -> Int { settings.updateInterval(url: url) }
    func setInterval(for url: String, _ hours: Int) { settings.setUpdateInterval(url: url, hours) }
    func onStart(for url: String) -> Bool { settings.updateOnStart(url: url) }
    func setOnStart(for url: String, _ on: Bool) { settings.setUpdateOnStart(url: url, on) }
    func groupEnabled(url: String, group: String) -> Bool {
        settings.groupEnabled(url: url, group: group)
    }

    func setGroupEnabled(url: String, group: String, _ on: Bool) {
        settings.setGroupEnabled(url: url, group: group, on)
    }

    // MARK: Custom EPG sources

    /// The playlist's custom sources, in added order.
    func sources(for url: String) -> [EpgSource] { (try? epgSourceStore.forPlaylist(url)) ?? [] }

    /// Adds a custom source; ignored (returns false) unless it is a valid
    /// http(s) URL. The store's unique index dedupes a repeat add.
    @discardableResult
    func addSource(playlistUrl: String, url: String) -> Bool {
        guard HttpUrl.isValid(url) else { return false }
        try? epgSourceStore.add(playlistUrl: playlistUrl, url: url,
                                nowMs: Int64(Date().timeIntervalSince1970 * 1_000))
        return true
    }

    /// Edits a custom source's URL; ignored (returns false) on an invalid URL.
    @discardableResult
    func setSourceUrl(id: Int64, url: String) -> Bool {
        guard HttpUrl.isValid(url) else { return false }
        try? epgSourceStore.setUrl(id: id, url: url)
        return true
    }

    func removeSource(id: Int64) { try? epgSourceStore.remove(id: id) }

    // MARK: App-wide EPG refresh

    /// The "Update EPG now" action: an unconditional forced EPG refresh.
    func refreshEpgNow() async { await refreshEpg() }

    /// Forces an EPG refresh iff the pure ``EpgRefreshPolicy`` says a completed
    /// update warrants one under the current app-wide toggle — decision stays
    /// testable and out of the view/`@Observable`.
    func maybeRefreshEpg(anyUpdated: Bool) async {
        guard EpgRefreshPolicy.shouldRefreshAfterPlaylistUpdate(
            anyUpdated: anyUpdated, updateOnChange: settings.updateOnPlaylistsChange) else { return }
        await refreshEpg()
    }
}
