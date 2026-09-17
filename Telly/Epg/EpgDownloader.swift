import Foundation

/// Fetches an EPG document over the network and turns raw bytes into an
/// `XmltvDocument`. The single real-I/O seam — the `data` closure — is injected
/// so the fetch/decompress/parse pipeline stays testable with a fake payload.
/// Unlike `HttpPlaylistFetcher` (which returns `String`, lossy for binary
/// gzip/xz guides) this keeps the bytes as `Data` all the way to `decompress`.
struct EpgDownloader {
    /// Real network fetch; the only line not exercised by tests.
    var data: (URL) async throws -> Data = { url in
        let (bytes, _) = try await URLSession.shared.data(from: url)
        return bytes
    }

    /// Fetches `epgUrl`, transparently decompresses (gzip/xz/plain), and parses.
    func download(epgUrl: String) async throws -> XmltvDocument {
        guard let url = URL(string: epgUrl) else { throw URLError(.badURL) }
        return XmltvParser.parse(CompressedXmltv.decompress(try await data(url)))
    }
}
