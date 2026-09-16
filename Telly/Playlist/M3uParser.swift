import Foundation

/// Parser for M3U playlists: `#EXTINF` entries, stream URLs, and the `url-tvg`
/// EPG hint. Ported from the Android `M3uParser`; pure and fully unit-tested.
enum M3uParser {
    static let header = "#EXTM3U"
    private static let extInf = "#EXTINF"
    private static let urlTvg = "url-tvg"
    private static let attributePattern = try! NSRegularExpression(pattern: #"([\w-]+)="([^"]*)""#)

    static func isHeader(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(header)
    }

    static func isExtInf(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(extInf)
    }

    /// Parses one `#EXTINF:-1 key="value",Title` line; nil when it is not one.
    static func parseExtInf(_ line: String) -> M3uEntry? {
        guard isExtInf(line) else { return nil }
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let colon = trimmed.firstIndex(of: ":") else { return nil }
        let body = String(trimmed[trimmed.index(after: colon)...])
        guard let comma = body.lastIndex(of: ",") else { return nil }
        let title = String(body[body.index(after: comma)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        return M3uEntry(title: title, attributes: attributes(in: body))
    }

    /// Attributes on an `#EXTM3U` header line (e.g. `url-tvg`); empty otherwise.
    static func headerAttributes(_ line: String) -> [String: String] {
        isHeader(line) ? attributes(in: line) : [:]
    }

    /// Parses a whole playlist body into channels plus the EPG URL hint.
    static func parse(_ content: String) -> M3uPlaylist {
        var epgURL: String?
        var pending: M3uEntry?
        var channels: [M3uChannel] = []
        for raw in content.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                continue
            } else if isHeader(line) {
                epgURL = headerAttributes(line)[urlTvg] ?? epgURL
            } else if isExtInf(line) {
                pending = parseExtInf(line)
            } else if line.hasPrefix("#") {
                continue
            } else {
                if let entry = pending { channels.append(entry.toChannel(streamURL: line)) }
                pending = nil
            }
        }
        return M3uPlaylist(epgURL: epgURL, channels: channels)
    }

    private static func attributes(in text: String) -> [String: String] {
        let range = NSRange(text.startIndex..., in: text)
        var result: [String: String] = [:]
        for m in attributePattern.matches(in: text, range: range) {
            guard let k = Range(m.range(at: 1), in: text),
                  let v = Range(m.range(at: 2), in: text) else { continue }
            result[String(text[k])] = String(text[v])
        }
        return result
    }
}
