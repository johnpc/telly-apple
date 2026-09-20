import Foundation

/// The user-triggered playlist refresh actions for ``PlaylistsSettingsModel``,
/// split out so the core stays within budget. Each returns an ``UpdateOutcome``
/// so the Settings controls can surface a spinner + success/failure message
/// (``UpdateActionButton``); the underlying fetch/import is unchanged — a failed
/// fetch leaves the stored copy intact, which is what the failure message reflects.
extension PlaylistsSettingsModel {
    /// Re-fetches one playlist, republishes, conditionally refreshes the EPG, then
    /// reports its post-update channel count (or a failure if the fetch failed).
    @discardableResult
    func updateNow(_ url: String) async -> UpdateOutcome {
        let updated = await updater.update(url)
        refreshed(); await maybeRefreshEpg(anyUpdated: updated)
        return .forOne(succeeded: updated, channelCount: channelCount(for: url))
    }

    /// Re-fetches every stored playlist, conditionally refreshes the EPG, then
    /// reports the total channel count (or a failure if none refreshed).
    @discardableResult
    func updateAll() async -> UpdateOutcome {
        let total = playlists.count
        let updated = await updater.updateAll(playlists.map(\.url))
        refreshed(); await maybeRefreshEpg(anyUpdated: !updated.isEmpty)
        return .forAll(succeeded: updated.count, total: total,
                       channelCount: (try? channelStore.totalCount()) ?? 0)
    }

    private func channelCount(for url: String) -> Int {
        guard let id = playlists.first(where: { $0.url == url })?.id else { return 0 }
        return (try? channelStore.channels(playlistId: Int(id)).count) ?? 0
    }
}
