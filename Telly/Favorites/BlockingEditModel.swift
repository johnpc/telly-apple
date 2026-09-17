import Foundation

/// Bulk "Manage blocking" editor (the Apple port of Android
/// `features/groups/BulkFlagSession`, BLOCKING kind): every channel with a
/// per-row blocked toggle that persists immediately. Sibling of
/// ``VisibilityEditModel`` — the difference is the parental gate: when parental
/// enforcement is enabled and a PIN is set, the editor is `locked` on entry
/// (``BulkFlagGate``) and a correct PIN via ``unlock(pin:)`` opens it.
@MainActor
@Observable
final class BlockingEditModel {
    let store: ChannelStore
    @ObservationIgnored let parental: ParentalStore
    var channels: [ChannelEntity] = []
    var locked: Bool

    init(store: ChannelStore, parental: ParentalStore) {
        self.store = store
        self.parental = parental
        locked = BulkFlagGate.locked(isEnabled: parental.isEnabled, isSet: parental.isSet)
    }

    func load() { channels = (try? store.allChannels()) ?? [] }

    /// Flips a channel's blocked flag, persists it, then reloads — a no-op while
    /// the editor is still PIN-locked.
    func toggleBlocked(_ channel: ChannelEntity) {
        guard !locked else { return }
        var updated = channel
        updated.flags.blocked.toggle()
        try? store.update(updated)
        load()
    }

    /// Opens the editor when `pin` verifies against the stored PIN; a wrong PIN
    /// leaves it locked.
    @discardableResult
    func unlock(pin: String) -> Bool {
        guard parental.verify(pin: pin) else { return false }
        locked = false
        return true
    }
}
