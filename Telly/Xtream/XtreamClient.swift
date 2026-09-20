import Foundation

/// The Xtream `player_api.php` client: authenticates, then pulls live + VOD
/// categories/streams and maps them into an ``M3uPlaylist`` for the shared import
/// path. Networking is the single injected `fetch` seam (JSON returned as text),
/// so the decode/compose logic is unit-tested against fixtures with no real
/// server. Auth failure throws ``XtreamError/unauthorized`` (surfaced as a
/// wizard error). Credentials are never logged.
struct XtreamClient {
    let fetch: (String) async throws -> String

    /// Auth handshake → live categories/streams → VOD categories/streams → map.
    func importPlaylist(_ creds: XtreamCredentials) async throws -> M3uPlaylist {
        try await authenticate(creds)
        return XtreamMapper.playlist(
            credentials: creds,
            liveCategories: try await get(creds, "get_live_categories"),
            liveStreams: try await get(creds, "get_live_streams"),
            vodCategories: try await get(creds, "get_vod_categories"),
            vodStreams: try await get(creds, "get_vod_streams"))
    }

    /// Validates the credentials via the handshake; throws when auth is rejected.
    func authenticate(_ creds: XtreamCredentials) async throws {
        let handshake: XtreamHandshake = try await decode(creds.apiUrl)
        guard handshake.userInfo?.authorized == true else { throw XtreamError.unauthorized }
    }

    private func get<T: Decodable>(_ creds: XtreamCredentials, _ action: String) async throws -> [T] {
        try await decode(creds.api(action: action))
    }

    private func decode<T: Decodable>(_ url: String) async throws -> T {
        let text = try await fetch(url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: Data(text.utf8))
    }
}

/// Import failures surfaced to the wizard / refresh path.
enum XtreamError: Error, Equatable { case unauthorized }
