import Foundation

/// URL construction for an ``XtreamCredentials`` — the `player_api.php` endpoints
/// (the stored identity + per-action calls), the auto-attached XMLTV EPG source,
/// and the live/movie stream URLs. Split from the core value type so each file
/// stays within budget. The live URLs match the conventional Xtream shape
/// ``XtreamUrl`` rewrites for catch-up, so catch-up keeps working unchanged.
extension XtreamCredentials {
    /// The handshake/identity URL (no `action`) — persisted as the playlist source.
    var apiUrl: String { api(action: nil) }

    /// The auto-registered XMLTV EPG source for the whole account.
    var xmltvUrl: String { "\(base)/xmltv.php?username=\(username)&password=\(password)" }

    /// `player_api.php` for an optional `action`, with the credentials query.
    func api(action: String?) -> String {
        let handshake = "\(base)/player_api.php?username=\(username)&password=\(password)"
        return action.map { "\(handshake)&action=\($0)" } ?? handshake
    }

    /// Live stream URL (`{base}/live/{u}/{p}/{id}.{ext}`), default container `ts`.
    func liveUrl(streamId: Int, ext: String = "ts") -> String {
        "\(base)/live/\(username)/\(password)/\(streamId).\(ext)"
    }

    /// Movie stream URL (`{base}/movie/{u}/{p}/{id}.{ext}`).
    func movieUrl(streamId: Int, ext: String) -> String {
        "\(base)/movie/\(username)/\(password)/\(streamId).\(ext)"
    }

    /// Reconstructs credentials from a stored ``apiUrl`` so a refresh can re-run
    /// the import. Nil when `url` is not an Xtream `player_api.php` URL.
    static func fromApiUrl(_ url: String) -> XtreamCredentials? {
        guard let comps = URLComponents(string: url), comps.path.hasSuffix("player_api.php"),
              let items = comps.queryItems, let scheme = comps.scheme, let host = comps.host,
              let user = items.first(where: { $0.name == "username" })?.value,
              let pass = items.first(where: { $0.name == "password" })?.value else { return nil }
        return XtreamCredentials(scheme: scheme, host: host, port: comps.port,
                                 username: user, password: pass)
    }

    /// True when `url` is a stored Xtream identity (routes a refresh to the client).
    static func isApiUrl(_ url: String) -> Bool { fromApiUrl(url) != nil }
}
