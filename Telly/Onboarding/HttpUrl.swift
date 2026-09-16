import Foundation

/// The http(s)-only URL rules the add-playlist wizard shares between validation
/// and the suggested-name step. Mirrors the Android use of OkHttp's
/// `toHttpUrlOrNull`: a URL is acceptable only when it has an http/https scheme
/// and a non-empty host.
enum HttpUrl {
    static func isValid(_ text: String) -> Bool { host(text) != nil }

    /// The URL's host (TiviMate pre-fills the playlist name with it), or nil
    /// when `text` is not a well-formed http(s) URL.
    static func host(_ text: String) -> String? {
        guard let components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else { return nil }
        return host
    }
}
