import Foundation

/// The entry list backing ``EpgAssignmentScreen``: every channel (hidden
/// included, the ``ChannelStore/allChannels()`` feed the bulk editors use), each
/// of which drills into its own per-channel ``AssignEpgModel`` picker. Mirrors
/// ``VisibilityEditModel`` — a thin list model that vends the per-row editor.
@MainActor
@Observable
final class EpgAssignmentModel {
    let store: ChannelStore
    @ObservationIgnored let programStore: ProgramStore
    var channels: [ChannelEntity] = []

    init(store: ChannelStore, programStore: ProgramStore) {
        self.store = store
        self.programStore = programStore
    }

    func load() { channels = (try? store.allChannels()) ?? [] }

    /// The per-channel Assign-EPG picker model for one row.
    func assignModel(for channel: ChannelEntity) -> AssignEpgModel {
        AssignEpgModel(store: store, programStore: programStore, channel: channel)
    }
}
