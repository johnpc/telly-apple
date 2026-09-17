import Foundation

/// Pure helpers for the group-management tools (Manage Groups) — the Apple port
/// of Android's `GroupNameSessions` guards. ``trimmedName`` is the shared
/// Create/Rename validator (trim whitespace; nil when the result is empty, so a
/// blank name is ignored); ``isCustom`` mirrors `GroupOptionsSession`'s lock —
/// Rename/Delete are offered ONLY for user-created custom groups (playlist
/// groups and the Favorites / All-channels pseudo-groups stay read-only). Leaf:
/// no dependencies, no I/O.
enum GroupOptions {
    /// The trimmed group name, or nil when it is empty after trimming whitespace.
    static func trimmedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// True iff a custom group carries `group` as its name — the gate for
    /// enabling Rename/Delete on a selected group.
    static func isCustom(_ group: String, in customs: [CustomGroup]) -> Bool {
        customs.contains { $0.name == group }
    }
}
