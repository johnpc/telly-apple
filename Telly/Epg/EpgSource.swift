/// One custom EPG source, attached to the playlist stored at `playlistUrl` —
/// the Apple mirror of the Android `EpgSource`. Pure: no persistence types, so
/// the host-name derivation is fully unit-testable. The auto-detected source
/// (the playlist's `url-tvg`) is NOT modelled here — it lives on the playlist
/// row and refreshes with it.
struct EpgSource: Equatable {
    let id: Int64
    let playlistUrl: String
    let url: String

    /// Display name: the URL's host, matching how the reference names sources.
    var name: String { Self.host(url) }

    /// Strips the scheme, path and port from `url`, leaving the bare host
    /// (`http://127.0.0.1:8000/epg.xml` → `127.0.0.1`); a blank/host-less
    /// result falls back to the input unchanged.
    static func host(_ url: String) -> String {
        let afterScheme = url.range(of: "://").map { String(url[$0.upperBound...]) } ?? url
        let beforeSlash = afterScheme.split(separator: "/", maxSplits: 1,
                                            omittingEmptySubsequences: false)[0]
        let host = beforeSlash.split(separator: ":", maxSplits: 1,
                                     omittingEmptySubsequences: false)[0]
        return host.isEmpty ? url : String(host)
    }
}
