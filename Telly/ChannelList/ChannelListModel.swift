import Foundation

/// The channel list's observable state: the visible channels, the selected
/// group filter, and the pseudo-group visibility. All list logic lives here so
/// the screen/rows stay pure SwiftUI. The Apple mirror of the Android panel
/// view-model's group/row derivation.
@MainActor
@Observable
final class ChannelListModel {
    let store: ChannelStore
    var channels: [ChannelEntity] = []
    /// The user-created custom groups, reloaded from the store alongside the
    /// channels so the group strip lists them after the playlist groups.
    var customGroups: [CustomGroup] = []
    var selectedGroup: String = ChannelPanelGroups.allChannels
    var visibility = GroupVisibility.standard
    /// The name/number search query; a non-empty value searches globally,
    /// overriding the selected group (see ``rows``).
    var query = ""
    /// Hides channels in disabled playlist groups; identity unless the composition
    /// root wires the shared ``PlaylistGroupFilter`` in (default keeps every channel).
    private let filter: ([ChannelEntity]) -> [ChannelEntity]
    /// The screen's load lifecycle: `loading` until the first read resolves into
    /// `loaded`/`empty`, or `failed` if a refresh of an empty store threw. Drives
    /// the skeleton / empty / error+retry treatment (`+Load`).
    var phase: LoadPhase = .loading
    /// Network refresh seam awaited on first appear (when the store is empty) and
    /// on Retry; the composition root wires the real playlist refresh, tests and
    /// the DEBUG screenshot harness inject a fake that succeeds/fails/stalls.
    var refresh: () async throws -> Void = {}

    init(store: ChannelStore, filter: @escaping ([ChannelEntity]) -> [ChannelEntity] = { $0 }) {
        self.store = store
        self.filter = filter
    }

    /// The group names offered by the picker, with hidden pseudo-groups dropped.
    var groups: [String] {
        visibility.filter(ChannelListGroups.groupNames(channels, customs: customGroups))
    }

    /// The rows shown: a non-empty trimmed query searches all channels globally
    /// (overriding the group filter), otherwise the selected group's channels.
    var rows: [ChannelEntity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? ChannelListGroups.channels(channels, in: selectedGroup, customs: customGroups)
            : ChannelSearch.filter(channels, query: query)
    }

    /// (Re)loads the visible channels and the custom groups from the store.
    /// Content always wins: a load that surfaces channels promotes `phase` to
    /// `.loaded`, so a late import (e.g. a cross-reinstall restore) reveals its
    /// rows even if the screen had already resolved to `.empty`.
    func load() {
        channels = filter((try? store.visibleChannels()) ?? [])
        customGroups = (try? CustomGroupStore(db: store.db).all()) ?? []
        if !channels.isEmpty { phase = .loaded }
    }

    /// Switches the active group filter.
    func select(_ group: String) { selectedGroup = group }
}
