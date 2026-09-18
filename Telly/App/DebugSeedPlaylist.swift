#if DEBUG
import Foundation

/// DEBUG-only real-provider seed config, parsed purely from the process
/// environment so a headless `simctl launch` can inject a live playlist/EPG (no
/// TCC-blocked keyboard entry needed for captures/QA). Unlike the fixture seams,
/// this drives the app's real network import. The URLs come ONLY from the
/// environment at runtime — nothing here is hardcoded or defaulted. The mapping
/// is a pure function so it stays unit-testable without any side effects.
struct DebugSeedPlaylist: Equatable {
    /// The M3U playlist URL to fetch + import (env ``playlistKey``).
    let playlistUrl: String
    /// Optional XMLTV EPG URL to attach + refresh (env ``epgKey``).
    let epgUrl: String?

    /// Env var naming the playlist (M3U) URL to import on launch.
    static let playlistKey = "TELLY_SEED_PLAYLIST_URL"
    /// Env var naming the optional EPG (XMLTV) URL to attach.
    static let epgKey = "TELLY_SEED_EPG_URL"

    /// Pure mapping: `environment` → optional seed config. Returns nil unless a
    /// valid http(s) playlist URL is present; a present-but-invalid EPG URL is
    /// dropped rather than failing the whole seed.
    static func from(environment: [String: String]) -> DebugSeedPlaylist? {
        guard let playlist = environment[playlistKey]?.trimmed,
              HttpUrl.isValid(playlist) else { return nil }
        let epg = environment[epgKey]?.trimmed
        let validEpg = epg.flatMap { HttpUrl.isValid($0) ? $0 : nil }
        return DebugSeedPlaylist(playlistUrl: playlist, epgUrl: validEpg)
    }
}
#endif
