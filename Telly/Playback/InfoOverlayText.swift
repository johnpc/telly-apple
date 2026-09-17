import Foundation

/// Pure formatting + empty-state decisions for the info overlay, keeping the
/// `*View` files free of `DateComponents`, `.details` chains and nil logic.
/// Time zone is injected (defaults to `.current`) so clock/label tests are
/// deterministic; the UTC-`Calendar` idiom mirrors ``XmltvTimestamp``.
enum InfoOverlayText {
    private static let calendar: Calendar = Calendar(identifier: .gregorian)

    /// Zero-padded `HH:mm` wall clock for `nowMs` in `timeZone`.
    static func clock(nowMs: Int, timeZone: TimeZone = .current) -> String {
        timeLabel(nowMs, timeZone: timeZone)
    }

    /// Zero-padded `HH:mm` for a programme boundary `ms` in `timeZone`.
    static func timeLabel(_ ms: Int, timeZone: TimeZone = .current) -> String {
        var cal = calendar
        cal.timeZone = timeZone
        let date = Date(timeIntervalSince1970: Double(ms) / 1_000)
        let parts = cal.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// True when there is a "now" programme to render; false → empty state.
    static func hasProgram(_ nowNext: NowNext?) -> Bool { nowNext?.now != nil }

    /// The current programme's title, or nil when absent.
    static func nowTitle(_ nowNext: NowNext?) -> String? { nowNext?.now?.details.title }

    /// The upcoming programme's title, or nil when absent.
    static func nextTitle(_ nowNext: NowNext?) -> String? { nowNext?.next?.details.title }
}
