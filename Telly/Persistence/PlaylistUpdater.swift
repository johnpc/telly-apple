/// Re-imports a stored playlist by re-fetching its source and re-parsing it —
/// the Apple mirror of Android's `PlaylistUpdater`. Each update is isolated:
/// a failed fetch (or store write) leaves the previously-stored copy untouched
/// and reports `false`, so `updateAll` returns only the URLs that succeeded.
/// Networking and the clock are injected, keeping the logic fully testable.
struct PlaylistUpdater {
    let fetch: (String) async throws -> String
    let store: PlaylistStore
    let now: () -> Int64

    /// Re-fetches and re-imports the playlist at `url`; the re-add replaces its
    /// channels while `PlaylistStore` carries user flags/overrides forward.
    /// Returns `false` (leaving the stored copy intact) on any fetch/store error.
    func update(_ url: String) async -> Bool {
        do {
            let text = try await fetch(url)
            let playlist = M3uParser.parse(text)
            return (try? store.add(sourceUrl: url, playlist: playlist, name: nil, nowMs: now())) != nil
        } catch {
            return false
        }
    }

    /// Updates each URL in turn, returning only those that refreshed successfully.
    func updateAll(_ urls: [String]) async -> [String] {
        var succeeded: [String] = []
        for url in urls where await update(url) {
            succeeded.append(url)
        }
        return succeeded
    }
}
