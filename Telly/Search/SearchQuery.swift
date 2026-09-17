import Foundation

/// Pure query preparation for the search screen (catalogue §4): trims and
/// collapses whitespace, then builds SQLite LIKE patterns with `%`/`_`/`\`
/// escaped so user input can never act as a wildcard. Channel numbers match
/// by prefix, but only when the whole query is digits — "2" finds channel
/// 2x, "news 2" never does. Callers normalize once, then pass the result to
/// ``nameLike(_:)``/``numberLike(_:)`` (no double-normalizing).
enum SearchQuery {
    /// Trim leading/trailing whitespace and collapse internal runs to one space.
    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.replacingOccurrences(
            of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Case-insensitive WORD-PREFIX pattern: the DAO compares against
    /// `' ' || column`, so the leading `"% "` anchors every word (the first
    /// included) — matches never start mid-word.
    static func nameLike(_ q: String) -> String { "% \(escape(q))%" }

    /// Channel-number prefix pattern; inert (matches nothing) for non-numeric
    /// or empty queries.
    static func numberLike(_ q: String) -> String {
        !q.isEmpty && q.allSatisfy(\.isNumber) ? "\(escape(q))%" : ""
    }

    /// SQL LIKE escaping with `\` as the escape char (pairs with `ESCAPE '\'`);
    /// backslash first so the escapes it introduces are not re-escaped.
    private static func escape(_ q: String) -> String {
        q.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }
}
