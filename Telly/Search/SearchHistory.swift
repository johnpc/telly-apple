import Foundation

/// The search screen's recent-query list (catalogue §4): committed queries,
/// most recent first, case-insensitively deduplicated and capped. Persisted
/// newline-joined in a string ``KeyValueStore`` — one list does not justify a
/// GRDB table (same reasoning as the last-channel-id decision).
struct SearchHistory {
    let store: KeyValueStore
    /// Settings → Search "Save search history"; off = no recording.
    let saveEnabled: () -> Bool

    init(store: KeyValueStore, saveEnabled: @escaping () -> Bool = { true }) {
        self.store = store
        self.saveEnabled = saveEnabled
    }

    /// The persisted queries, most recent first (blank lines dropped).
    func list() -> [String] {
        (store.readString(Self.key) ?? "")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Records a committed query; re-searching moves it back to the front.
    func record(_ raw: String) {
        guard saveEnabled() else { return }
        let q = SearchQuery.normalize(raw)
        guard !q.isEmpty else { return }
        let entries = [q] + list().filter { $0.caseInsensitiveCompare(q) != .orderedSame }
        store.writeString(entries.prefix(Self.maxEntries).joined(separator: "\n"), Self.key)
    }

    /// Clears the whole history (the header's trash affordance).
    func clear() { store.remove(Self.key) }

    private static let key = "search.history"
    private static let maxEntries = 20
}
