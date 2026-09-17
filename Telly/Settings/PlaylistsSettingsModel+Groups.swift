import Foundation

/// Group-tools factories vended off the cap-safe ``PlaylistsSettingsModel``
/// carrier (the `SettingsStore+Search` / `+Keymap` sibling-extension precedent),
/// so the new Settings sections consume `playlists.makeX()` without growing any
/// capped file. The ``ProgramStore`` is built from the shared database the
/// carrier's ``ChannelStore`` already holds, so no new stored property or
/// factory-threading is needed.
extension PlaylistsSettingsModel {
    /// The per-channel EPG-assignment entry list model (backing
    /// ``EpgAssignmentScreen``); each row drills into an ``AssignEpgModel``.
    func makeEpgAssignmentModel() -> EpgAssignmentModel {
        EpgAssignmentModel(store: channelStore, programStore: ProgramStore(db: channelStore.db))
    }
}
