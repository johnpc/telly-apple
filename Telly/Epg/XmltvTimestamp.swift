import Foundation

/// Parses XMLTV timestamps such as `20260913123000 +0000` into epoch millis.
/// Epoch-Int based to mirror the Android port; a UTC `Calendar` does the
/// civil-time → instant conversion, then the `±HHMM` offset is subtracted.
enum XmltvTimestamp {
    private static let pattern = try! NSRegularExpression(
        pattern: #"^(\d{8})(\d{6})(?:\s*([+-]\d{4}))?$"#)
    private static let msPerMinute = 60_000
    private static let minutesPerHour = 60

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Epoch millis for `raw`, or nil when it is not a full XMLTV timestamp.
    static func parseMs(_ raw: String?) -> Int? {
        let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let range = NSRange(text.startIndex..., in: text)
        guard let match = pattern.firstMatch(in: text, range: range),
              let date = group(match, 1, text), let time = group(match, 2, text),
              let utc = utcMs(date: date, time: time) else { return nil }
        return utc - offsetMs(group(match, 3, text))
    }

    private static func utcMs(date: String, time: String) -> Int? {
        let d = Array(date), t = Array(time)
        var comps = DateComponents()
        comps.year = Int(String(d[0..<4])); comps.month = Int(String(d[4..<6]))
        comps.day = Int(String(d[6..<8])); comps.hour = Int(String(t[0..<2]))
        comps.minute = Int(String(t[2..<4])); comps.second = Int(String(t[4..<6]))
        guard let instant = utcCalendar.date(from: comps) else { return nil }
        return Int((instant.timeIntervalSince1970 * 1000).rounded())
    }

    /// Millis east of UTC for `+HHMM`/`-HHMM`; 0 for a missing offset.
    private static func offsetMs(_ offset: String?) -> Int {
        guard let chars = offset.map(Array.init), chars.count == 5,
              let hours = Int(String(chars[1..<3])),
              let minutes = Int(String(chars[3..<5])) else { return 0 }
        let magnitude = (hours * minutesPerHour + minutes) * msPerMinute
        return chars[0] == "-" ? -magnitude : magnitude
    }

    private static func group(_ match: NSTextCheckingResult, _ index: Int, _ text: String) -> String? {
        guard let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }
}
