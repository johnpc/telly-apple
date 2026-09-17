import Foundation

/// `catchup="xc"` (Xtream Codes): a live URL of the conventional
/// `http(s)://host[:port][/live]/user/pass/id[.ext]` shape becomes the standard
/// timeshift endpoint
/// `http(s)://host[:port]/timeshift/user/pass/{durationMinutes}/{yyyy-MM-dd:HH-mm}/{id}.ts`.
/// Ported 1:1 from Android `XtreamUrl` (XtreamUrl.kt:14-33).
enum XtreamUrl {
    private static let pattern =
        "^(https?://[^/]+)(?:/live)?/([^/?]+/[^/?]+)/(\\d+)(?:\\.\\w+)?(?:\\?.*)?$"

    /// Nil when the live URL is not the conventional Xtream Codes shape.
    static func build(streamUrl: String, startMs: Int, endMs: Int) -> String? {
        guard let match = firstMatch(in: streamUrl) else { return nil }
        let host = group(match, 1, in: streamUrl)
        let credentials = group(match, 2, in: streamUrl)
        let id = group(match, 3, in: streamUrl)
        // Duration rounds UP to whole minutes (Android XtreamUrl.kt:26/28).
        let minutes = (endMs - startMs + 59_999) / 60_000
        return "\(host)/timeshift/\(credentials)/\(minutes)/\(stamp(startMs))/\(id).ts"
    }

    private static func firstMatch(in url: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        return regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url))
    }

    private static func group(_ match: NSTextCheckingResult, _ index: Int, in url: String) -> String {
        guard let range = Range(match.range(at: index), in: url) else { return "" }
        return String(url[range])
    }

    private static func stamp(_ atMs: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd:HH-mm"
        return formatter.string(from: Date(timeIntervalSince1970: Double(atMs) / 1_000))
    }
}
