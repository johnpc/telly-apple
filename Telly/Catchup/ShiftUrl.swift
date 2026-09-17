import Foundation

/// `catchup="shift"`: the conventional timeshift form — the live stream URL with
/// `utc` (programme start) and `lutc` (request time) query parameters appended,
/// both in epoch seconds. Ported 1:1 from Android `ShiftUrl` (ShiftUrl.kt:12-16).
enum ShiftUrl {
    static func build(streamUrl: String, startMs: Int, nowMs: Int) -> String {
        let separator = streamUrl.contains("?") ? "&" : "?"
        let start = CatchupTemplate.seconds(startMs)
        let now = CatchupTemplate.seconds(nowMs)
        return "\(streamUrl)\(separator)utc=\(start)&lutc=\(now)"
    }
}
