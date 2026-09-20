#if DEBUG
import Testing
@testable import Telly

/// The DEBUG Xtream seed's pure env→config mapping and its offline import path.
/// Every value here is a FAKE `example.com` / `demo` placeholder — never a real
/// provider — so the seam is proven without any real network or credential.
@MainActor
struct DebugSeedXtreamTests {
    private static let env = [
        DebugSeedXtream.serverKey: "http://example.com:8080",
        DebugSeedXtream.userKey: "demo",
        DebugSeedXtream.passKey: "demo",
    ]

    /// Fixture JSON routed by the request's `action` (handshake = no action).
    private func fetch(_ url: String) async throws -> String {
        if url.contains("get_live_categories") { return #"[{"category_id":"1","category_name":"News"}]"# }
        if url.contains("get_live_streams") {
            return #"[{"stream_id":1,"name":"News One","category_id":"1","tv_archive":0}]"#
        }
        if url.contains("get_vod") { return "[]" }
        return #"{"user_info":{"auth":1,"status":"Active"}}"#
    }

    @Test func mapsCredentialsFromEnvironment() {
        let seed = DebugSeedXtream.from(environment: Self.env)
        #expect(seed?.credentials?.host == "example.com")
        #expect(seed?.credentials?.username == "demo")
    }

    @Test func nilWhenAnyFieldMissing() {
        #expect(DebugSeedXtream.from(environment: [:]) == nil)
        #expect(DebugSeedXtream.from(environment: [DebugSeedXtream.serverKey: "http://example.com"]) == nil)
    }

    @Test func seedImportsChannelsThroughRealStore() async throws {
        let env = AppEnvironment(database: try AppDatabase.makeInMemory())
        await env.seedXtreamIfRequested(environment: Self.env, fetch: fetch)
        #expect(env.playlists.count == 1)
        #expect(try env.channelStore.visibleChannels().map(\.source.name) == ["News One"])
    }

    @Test func noOpWhenEnvironmentUnset() async throws {
        let env = AppEnvironment(database: try AppDatabase.makeInMemory())
        await env.seedXtreamIfRequested(environment: [:], fetch: fetch)
        #expect(env.playlists.isEmpty)
    }
}
#endif
