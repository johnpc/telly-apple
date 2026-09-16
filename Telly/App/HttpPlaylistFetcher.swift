import Foundation

/// Fetches a playlist or EPG document over http(s). The single piece of real
/// networking glue in the onboarding slice — the wizard takes this as an
/// injected async closure, so its logic stays testable with a fake fetcher.
enum HttpPlaylistFetcher {
    static func fetch(_ text: String) async throws -> String {
        guard let url = URL(string: text) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }
}
