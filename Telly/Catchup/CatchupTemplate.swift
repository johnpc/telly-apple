import Foundation

/// Substitutes the community-standard placeholders of a `catchup-source`
/// template. All values are epoch SECONDS (`{offset}`/`{duration}` are spans in
/// seconds); both the `{x}` and `${x}` spellings are accepted. Ported 1:1 from
/// Android `CatchupTemplate` (CatchupTemplate.kt:12-40).
///
/// SECURITY: a FIXED token whitelist + pure string interpolation only — no
/// shell, no eval. Unknown tokens pass through verbatim (never error, never run).
enum CatchupTemplate {
    /// Epoch/duration millis to the whole seconds catch-up URLs carry.
    static func seconds(_ ms: Int) -> Int { ms / 1_000 }

    static func expand(_ template: String, startMs: Int, endMs: Int, nowMs: Int) -> String {
        let start = seconds(startMs)
        let now = seconds(nowMs)
        let values: [(String, Int)] = [
            ("utc", start),
            ("start", start),
            ("lutc", now),
            ("now", now),
            ("timestamp", now),
            ("offset", now - start),
            ("duration", seconds(endMs - startMs)),
        ]
        // "${x}" first: replacing the inner "{x}" first would strand the "$".
        return values.reduce(template) { acc, pair in
            substitute(acc, key: pair.0, value: pair.1)
        }
    }

    private static func substitute(_ text: String, key: String, value: Int) -> String {
        text
            .replacingOccurrences(of: "${\(key)}", with: String(value))
            .replacingOccurrences(of: "{\(key)}", with: String(value))
    }
}
