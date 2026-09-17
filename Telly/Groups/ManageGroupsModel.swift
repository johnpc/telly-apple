import Foundation

/// The Manage-Groups editor state — the Apple port of Android's
/// `CreateGroupSession` + `GroupOptionsSession`: the observed list of custom
/// groups plus create / rename / delete actions. Create makes an EMPTY group
/// (Copy channels populates it in a later slice); a blank name is ignored via
/// ``GroupOptions/trimmedName(_:)``. Every mutation persists through the
/// ``CustomGroupStore`` and then reloads the observed feed.
@MainActor
@Observable
final class ManageGroupsModel {
    let store: CustomGroupStore
    var groups: [CustomGroup] = []

    init(store: CustomGroupStore) { self.store = store }

    /// Re-reads the stored custom groups into the observed feed.
    func load() { groups = (try? store.all()) ?? [] }

    /// Creates a new EMPTY custom group; a blank/whitespace name is ignored.
    func create(_ raw: String) {
        guard let name = GroupOptions.trimmedName(raw) else { return }
        _ = try? store.create(name: name)
        load()
    }

    /// Renames group `id`; a blank/whitespace name is ignored.
    func rename(id: Int, _ raw: String) {
        guard let name = GroupOptions.trimmedName(raw) else { return }
        try? store.rename(id: id, name: name)
        load()
    }

    /// Deletes group `id` (its membership cascades in the store).
    func delete(id: Int) {
        try? store.delete(id: id)
        load()
    }
}
