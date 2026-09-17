import Foundation

/// Orchestrates EPG refresh across the stored playlists — the Apple mirror of
/// the Android `EpgRefresher`. All seams are injected (downloader, clock, warn,
/// custom sources) so the decision logic is fully testable without I/O or a
/// wall clock. Per playlist: fetch each source into the `ProgramStore`,
/// stamping the playlist iff at least one source succeeded, then trim the past.
struct EpgRefresher {
    let playlistStore: PlaylistStore
    let programStore: ProgramStore
    /// Fetches+parses one source URL into a document (see `EpgDownloader`).
    let download: (String) async throws -> XmltvDocument
    /// Injected clock (epoch millis) — no wall-clock read lives in the logic.
    let now: () -> Int
    /// Keep programme descriptions on import (E5 passes the default true).
    var keepDescriptions: Bool = true
    /// Extra per-playlist EPG sources (E7 fills this; default: none).
    var customSources: (String) -> [String] = { _ in [] }
    /// Non-fatal diagnostics sink for a failed source (default: no-op).
    var warn: (String) -> Void = { _ in }
    /// Millis between refreshes; 0 disables interval refresh. From the settings
    /// store via `AppEnvironment`; the memberwise default keeps call sites intact.
    var intervalMs = RefreshScheduler.defaultIntervalMs
    /// Keep-past retention horizon in millis for the trim after each refresh.
    var keepPastMs = RefreshScheduler.defaultKeepPastMs

    /// Refreshes only the playlists whose guide data is due, then trims.
    func refreshDue() async throws {
        try await run(onlyDue: true)
    }

    /// Refreshes every playlist regardless of due-ness, then trims.
    func refreshAllNow() async throws {
        try await run(onlyDue: false)
    }

    /// Playlist-set change hook: refresh the due playlists when enabled.
    func onPlaylistsChanged(updateOnChange: Bool) async throws {
        if updateOnChange { try await refreshDue() }
    }

    /// Shared loop: refresh each (optionally due-filtered) playlist, then trim
    /// programmes that ended before the keep-past cutoff.
    private func run(onlyDue: Bool) async throws {
        let nowMs = now()
        for playlist in try playlistStore.all() where !onlyDue || isDue(playlist, nowMs) {
            await refresh(playlist, nowMs: nowMs)
        }
        try programStore.trimEndedBefore(cutoffMs: nowMs - keepPastMs)
    }

    /// True when `playlist` is due for a refresh under the configured interval.
    private func isDue(_ playlist: PlaylistEntity, _ nowMs: Int) -> Bool {
        RefreshScheduler.isDue(lastUpdatedMs: Int(playlist.epgLastUpdatedMs),
                               nowMs: nowMs, intervalMs: intervalMs)
    }

    /// Refreshes one playlist across its sources, swallowing per-source
    /// failures; stamps `epgLastUpdatedMs` only if at least one source loaded.
    private func refresh(_ playlist: PlaylistEntity, nowMs: Int) async {
        let sources = sources(for: playlist)
        guard !sources.isEmpty else { return }
        var anySucceeded = false
        for source in sources {
            do {
                let document = try await download(source)
                try programStore.upsertReplacing(document: document, keepDescriptions: keepDescriptions)
                anySucceeded = true
            } catch {
                warn("EPG source failed \(source): \(error)")
            }
        }
        if anySucceeded, let id = playlist.id {
            try? playlistStore.markEpgUpdated(id: id, nowMs: Int64(nowMs))
        }
    }

    /// The ordered source URLs for a playlist: its `epgUrl` then custom sources.
    private func sources(for playlist: PlaylistEntity) -> [String] {
        (playlist.epgUrl.map { [$0] } ?? []) + customSources(playlist.url)
    }
}
