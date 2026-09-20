#if DEBUG
import Foundation

/// DEBUG-only Xtream seed config, parsed purely from the process environment so a
/// headless `simctl launch` can import a real Xtream account without TCC-blocked
/// keyboard entry. Mirrors ``DebugSeedPlaylist``: the server/credentials come
/// ONLY from the environment at runtime — nothing here is hardcoded or defaulted,
/// and credentials are never logged. The mapping is a pure, unit-testable function.
struct DebugSeedXtream: Equatable {
    let server: String
    let username: String
    let password: String

    /// Env vars naming the Xtream server + credentials to import on launch.
    static let serverKey = "TELLY_SEED_XTREAM_URL"
    static let userKey = "TELLY_SEED_XTREAM_USER"
    static let passKey = "TELLY_SEED_XTREAM_PASS"

    /// Pure mapping: `environment` → optional seed. Returns nil unless all three
    /// fields are present and parse into valid ``XtreamCredentials``.
    static func from(environment: [String: String]) -> DebugSeedXtream? {
        guard let server = environment[serverKey]?.nonBlank,
              let user = environment[userKey]?.nonBlank,
              let pass = environment[passKey]?.nonBlank,
              XtreamCredentials.parse(server: server, username: user, password: pass) != nil
        else { return nil }
        return DebugSeedXtream(server: server, username: user, password: pass)
    }

    /// The parsed credentials for this seed (validated by ``from(environment:)``).
    var credentials: XtreamCredentials? {
        XtreamCredentials.parse(server: server, username: username, password: password)
    }
}
#endif
