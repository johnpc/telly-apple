import Foundation

/// `catchup="flussonic"`: the standard Flussonic/Media-Server archive rewrite of
/// the live URL's last path segment (query string preserved):
/// `…/mono.m3u8` → `…/archive-{start}-{duration}.m3u8`,
/// `…/video.m3u8` → `…/video-{start}-{duration}.m3u8`,
/// `…/mpegts`     → `…/archive-{start}-{duration}.ts`.
/// Ported 1:1 from Android `FlussonicUrl` (FlussonicUrl.kt:12-27).
enum FlussonicUrl {
    static func build(streamUrl: String, startMs: Int, endMs: Int) -> String {
        let start = CatchupTemplate.seconds(startMs)
        let duration = CatchupTemplate.seconds(endMs - startMs)
        let base = streamUrl.components(separatedBy: "?")[0]
        let query = String(streamUrl.dropFirst(base.count))
        let (head, last) = splitLastPath(base)
        let archive = archiveName(for: last, start: start, duration: duration)
        return "\(head)/\(archive)\(query)"
    }

    /// Everything before / after the last `/`; both fall back to `base` when it
    /// has no `/` (Kotlin `substringBeforeLast`/`substringAfterLast` semantics).
    private static func splitLastPath(_ base: String) -> (String, String) {
        guard let slash = base.lastIndex(of: "/") else { return (base, base) }
        return (String(base[..<slash]), String(base[base.index(after: slash)...]))
    }

    private static func archiveName(for segment: String, start: Int, duration: Int) -> String {
        switch segment {
        case "mpegts": return "archive-\(start)-\(duration).ts"
        case "video.m3u8": return "video-\(start)-\(duration).m3u8"
        default: return "archive-\(start)-\(duration).m3u8"
        }
    }
}
