import Foundation

/// Fetches a playlist or EPG document over http(s). The single piece of real
/// networking glue in the onboarding slice — the wizard takes this as an
/// injected async closure, so its logic stays testable with a fake fetcher.
/// A bounded request/resource timeout keeps a stalled provider from hanging the
/// fetch forever; the wizard/refresh layers surface it as a recoverable error.
enum HttpPlaylistFetcher {
    /// Seconds a single request (and the whole resource) may take before the
    /// URL loading system fails it — mirrors the ~25s UI timeout.
    static let timeoutSeconds: TimeInterval = 25

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutSeconds
        config.timeoutIntervalForResource = timeoutSeconds
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    static func fetch(_ text: String) async throws -> String {
        guard let url = URL(string: text) else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }
}
