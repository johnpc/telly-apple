import Foundation

/// The per-channel "Assign EPG" picker's state core (Apple port of Android
/// `AssignEpgSession`): the channel being edited, the EPG ids that hold stored
/// programme data (from ``ProgramStore/channelIds()``), and the derived picker
/// ``rows``. ``select(_:)`` persists the chosen override — which survives
/// playlist refreshes with the rest of ``ChannelOverrides`` — then re-marks it.
@MainActor
@Observable
final class AssignEpgModel {
    let store: ChannelStore
    @ObservationIgnored let programStore: ProgramStore
    var channel: ChannelEntity
    var epgIds: [String] = []

    init(store: ChannelStore, programStore: ProgramStore, channel: ChannelEntity) {
        self.store = store
        self.programStore = programStore
        self.channel = channel
    }

    /// The picker rows for the current channel + loaded EPG ids.
    var rows: [AssignEpgOption] { AssignEpgOptions.rows(channel: channel, epgIds: epgIds) }

    /// Loads the EPG ids that currently hold stored programme data.
    func load() { epgIds = (try? programStore.channelIds()) ?? [] }

    /// Persists the chosen EPG override (nil = Auto) and updates the local channel
    /// so the picker re-marks the selection.
    func select(_ override: String?) {
        let updated = AssignEpgOptions.applied(channel, override: override)
        try? store.update(updated)
        channel = updated
    }
}
