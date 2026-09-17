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
    var selectedGroup: String = ChannelPanelGroups.allChannels
    var visibility = GroupVisibility.standard

    init(store: ChannelStore) { self.store = store }

    /// The group names offered by the picker, with hidden pseudo-groups dropped.
    var groups: [String] { visibility.filter(ChannelListGroups.groupNames(channels)) }

    /// The rows shown for the selected group.
    var rows: [ChannelEntity] { ChannelListGroups.channels(channels, in: selectedGroup) }

    /// (Re)loads the visible channels from the store.
    func load() { channels = (try? store.visibleChannels()) ?? [] }

    /// Switches the active group filter.
    func select(_ group: String) { selectedGroup = group }
}
