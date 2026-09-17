import Foundation

/// The Copy-channels editor state — the Apple port of Android's
/// `CopyChannelsSession`: pick a target custom group (the picker is skipped when
/// exactly one exists; an empty state prompts "Create a custom group first" when
/// there are none), check channels (HIDDEN channels are excluded via
/// ``CopyChannelsPlan/selectableChannels(_:)``), and ``commit()`` copies the
/// checked channels into the group by refresh-stable key. Already-present keys
/// are no-ops (the store's `addMembers` uses INSERT OR IGNORE).
@MainActor
@Observable
final class CopyChannelsModel {
    let store: CustomGroupStore
    let channelStore: ChannelStore
    var groups: [CustomGroup] = []
    var channels: [ChannelEntity] = []
    var target: CustomGroup?
    var selection: Set<Int> = []
    /// Invoked after a successful ``commit()`` — the screen uses it to dismiss.
    @ObservationIgnored var onDone: (() -> Void)?

    init(store: CustomGroupStore, channelStore: ChannelStore, target: CustomGroup? = nil) {
        self.store = store
        self.channelStore = channelStore
        self.target = target
    }

    /// Loads the custom groups and the selectable (non-hidden) channels; when no
    /// target was supplied, defaults to the sole group if there is exactly one.
    func load() {
        groups = (try? store.all()) ?? []
        channels = CopyChannelsPlan.selectableChannels((try? channelStore.allChannels()) ?? [])
        if target == nil { target = CopyChannelsPlan.defaultTarget(groups) }
    }

    /// Toggles a channel's checked state (identified by ``ChannelEntity/id``).
    func toggle(_ channel: ChannelEntity) {
        if selection.contains(channel.id) { selection.remove(channel.id) }
        else { selection.insert(channel.id) }
    }

    /// Chooses the target custom group (the multi-group picker).
    func pickTarget(_ group: CustomGroup) { target = group }

    /// Copies the checked channels into the target group by refresh-stable key
    /// (no-op when no target); already-present keys are ignored. Then `onDone`.
    func commit() {
        guard let target else { return }
        try? store.addMembers(id: target.id, keys: CopyChannelsPlan.keys(of: selection, in: channels))
        onDone?()
    }
}
