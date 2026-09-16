import Testing
@testable import Telly

/// Unit coverage for the per-channel now/next fold.
struct NowNextResolverTests {

    private func program(_ channel: String, _ start: Int, _ end: Int, _ title: String) -> ProgramEntity {
        ProgramEntity(channelTvgId: channel, startMs: start, endMs: end,
                      details: ProgramDetails(title: title))
    }

    @Test func resolvesNowAndNextPerChannel() {
        let programs = [
            program("a", 0, 100, "a-past"),
            program("a", 100, 200, "a-now"),
            program("a", 200, 300, "a-next"),
            program("b", 150, 250, "b-now"),
        ]
        let result = NowNextResolver.resolve(programs, atMs: 150)
        #expect(result["a"]?.now?.details.title == "a-now")
        #expect(result["a"]?.next?.details.title == "a-next")
        #expect(result["b"]?.now?.details.title == "b-now")
        #expect(result["b"]?.next == nil)
    }

    @Test func omitsChannelsWithNoAiringOrUpcomingRow() {
        let result = NowNextResolver.resolve([program("a", 0, 100, "done")], atMs: 500)
        #expect(result["a"]?.now == nil)
        #expect(result["a"]?.next == nil)
        #expect(result.count == 1)
    }
}
