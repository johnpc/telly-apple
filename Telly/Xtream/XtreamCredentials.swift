import Foundation

/// Xtream Codes connection: the base server (scheme/host/optional port) plus the
/// user credentials. Pure value type — parsing user input and building the
/// `player_api.php`/stream/xmltv URLs (in `+Urls`) are side-effect-free and
/// unit-tested. Credentials are never logged; the derived `apiUrl` is the
/// playlist's stored identity, mirroring how M3U `get.php` URLs already carry
/// their credentials in the URL query.
struct XtreamCredentials: Equatable, Sendable {
    let scheme: String
    let host: String
    let port: Int?
    let username: String
    let password: String

    /// `{scheme}://{host}[:{port}]` — no trailing slash.
    var base: String {
        port.map { "\(scheme)://\(host):\($0)" } ?? "\(scheme)://\(host)"
    }

    /// Parses a server field (`http://host:8080`, `host:8080`, bare `host`, or a
    /// value with a trailing slash/path) plus username/password. Nil when the
    /// host is blank or either credential is empty; a missing scheme defaults to
    /// `http` (Xtream servers are commonly plain HTTP).
    static func parse(server: String, username: String, password: String) -> XtreamCredentials? {
        guard let user = username.nonBlank, let pass = password.nonBlank,
              let (scheme, host, port) = endpoint(server.trimmed) else { return nil }
        return XtreamCredentials(scheme: scheme, host: host, port: port,
                                 username: user, password: pass)
    }

    /// Splits a server string into scheme/host/port, tolerating a missing scheme
    /// and a trailing slash or path. Nil when no http(s) host can be found.
    static func endpoint(_ server: String) -> (String, String, Int?)? {
        let withScheme = server.contains("://") ? server : "http://\(server)"
        guard let comps = URLComponents(string: withScheme),
              let scheme = comps.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = comps.host, !host.isEmpty else { return nil }
        return (scheme, host, comps.port)
    }
}
