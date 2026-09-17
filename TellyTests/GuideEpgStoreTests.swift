import Testing
import GRDB
@testable import Telly

/// The observable guide feed: now/next resolution at a fixed clock, per-channel
/// offset application, nil-safe lookup, and absence of channels with no data.
@MainActor
struct GuideEpgStoreTests {
    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "G", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ ch: String, _ start: Int, _ end: Int, _ title: String) -> XmltvProgram {
        XmltvProgram(channelId: ch, startMs: start, endMs: end,
                     details: ProgramDetails(title: title, subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    /// Seeds channels a/b/c (b optionally offset) plus programmes on a and b,
    /// then builds the store at a fixed clock. Channel c is left dataless.
    private func makeStore(offsetB: Int, now: Int) throws -> GuideEpgStore {
        let db = try AppDatabase.makeInMemory()
        _ = try PlaylistStore(db: db).add(
            sourceUrl: "u", playlist: M3uPlaylist(channels: [m("a"), m("b"), m("c")]),
            name: nil, nowMs: 0)
        if offsetB != 0 {
            try db.queue.write {
                try $0.execute(sql: "UPDATE channels SET epgOffsetMinutes = ? WHERE tvgId = 'b'",
                               arguments: [offsetB])
            }
        }
        try ProgramStore(db: db).upsertReplacing(document: XmltvDocument(channels: [], programs: [
            prog("a", 0, 120_000, "NowA"), prog("a", 120_000, 240_000, "NextA"),
            prog("b", 720_000, 1_200_000, "OnlyB")]), keepDescriptions: true)
        return GuideEpgStore(channelStore: ChannelStore(db: db),
                             repository: EpgRepository(store: ProgramStore(db: db)),
                             now: { now })
    }

    @Test func resolvesNowAndNextForSeededChannel() throws {
        let store = try makeStore(offsetB: 0, now: 60_000)
        store.refresh()
        #expect(store.nowNext(forEpgId: "a")?.now?.details.title == "NowA")
        #expect(store.nowNext(forEpgId: "a")?.next?.details.title == "NextA")
    }

    @Test func nonZeroOffsetShiftsSelection() throws {
        let shifted = try makeStore(offsetB: -4, now: 600_000)
        let unshifted = try makeStore(offsetB: 0, now: 600_000)
        shifted.refresh()
        unshifted.refresh()
        #expect(shifted.nowNext(forEpgId: "b")?.now?.details.title == "OnlyB")
        #expect(unshifted.nowNext(forEpgId: "b")?.now == nil)
        #expect(unshifted.nowNext(forEpgId: "b")?.next?.details.title == "OnlyB")
    }

    @Test func lookupIsNilSafeAndChannelWithoutDataIsAbsent() throws {
        let store = try makeStore(offsetB: 0, now: 60_000)
        store.refresh()
        #expect(store.nowNext(forEpgId: nil) == nil)
        #expect(store.nowNext(forEpgId: "zzz") == nil)
        #expect(store.nowNext(forEpgId: "c") == nil)
        #expect(store.nowNextByChannel["c"] == nil)
    }
}
