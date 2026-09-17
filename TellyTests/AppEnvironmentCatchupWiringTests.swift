import Testing
import GRDB
@testable import Telly

/// The composition-root wiring for catch-up transport: `makeCatchupPlaybackModel`
/// must build a model over a fresh engine and the environment's real EPG
/// repository without auto-starting (the screen starts it in `.task`).
@MainActor
struct AppEnvironmentCatchupWiringTests {
    private func channel() -> ChannelEntity {
        ChannelEntity(
            playlistId: 1, number: 1, sortIndex: 0,
            source: ChannelSource(name: "News", groupTitle: nil, logoUrl: nil,
                                  streamUrl: "http://127.0.0.1/live/news.ts", tvgId: "news.tv"),
            catchup: ChannelCatchup(catchupType: "default",
                                    catchupSource: "http://127.0.0.1/a?utc=${start}&dur=${duration}",
                                    catchupDays: 7))
    }

    @Test func makeCatchupPlaybackModelConstructsWithoutStarting() throws {
        let db = try AppDatabase.makeInMemory()
        let env = AppEnvironment(database: db, now: { 10_000_000_000 })
        let request = CatchupRequest(channel: channel(), url: "http://127.0.0.1/archive",
                                     title: "R", startMs: 0, endMs: 60_000)
        let model = env.makeCatchupPlaybackModel(request: request)
        #expect(model.state == nil)     // not auto-started
        #expect(model.mode == .none)
    }
}
