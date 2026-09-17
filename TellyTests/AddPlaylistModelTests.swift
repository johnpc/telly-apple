import Testing
@testable import Telly

/// The add-playlist wizard state machine, driven against a fake fetcher and an
/// in-memory database — mirrors the Android `AddPlaylistViewModel` tests.
@MainActor
struct AddPlaylistModelTests {
    private static let m3u = """
    #EXTM3U url-tvg="http://epg.example/guide.xml"
    #EXTINF:-1 tvg-id="a" group-title="News",A
    http://x/a.ts
    #EXTINF:-1 tvg-id="b" group-title="Movies",B
    http://x/b.mp4
    """

    private func make(_ fetch: @escaping (String) async throws -> String) throws
        -> (AddPlaylistModel, PlaylistStore, ChannelStore) {
        let db = try AppDatabase.makeInMemory()
        let store = PlaylistStore(db: db)
        let model = AddPlaylistModel(fetch: fetch, store: store, now: { 42 })
        return (model, store, ChannelStore(db: db))
    }

    struct Boom: Error {}

    @Test func choosingM3uOpensTheUrlStep() throws {
        let (model, _, _) = try make { _ in "" }
        model.chooseType(.m3u)
        #expect(model.state.step == .urlEntry)
    }

    @Test func nonHttpUrlIsRejectedWithoutLeavingTheStep() async throws {
        let (model, _, _) = try make { _ in Self.m3u }
        model.chooseType(.m3u)
        model.setUrl("ftp://nope")
        await model.submitUrl()
        #expect(model.state.step == .urlEntry)
        #expect(model.state.error == .invalidURL)
    }

    @Test func validUrlProcessesAndSummarizes() async throws {
        let (model, _, _) = try make { _ in Self.m3u }
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        #expect(model.state.step == .processed)
        #expect(model.state.name == "host.tv")
        #expect(model.state.liveCount == 1)
        #expect(model.state.movieCount == 1)
        #expect(model.state.groupCount == 2)
        #expect(model.state.channelCount == 2)
    }

    @Test func fetchFailureReturnsToUrlStepWithError() async throws {
        let (model, _, _) = try make { _ in throw Boom() }
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        #expect(model.state.step == .urlEntry)
        #expect(model.state.error == .loadFailed)
    }

    @Test func confirmPrefillsTheEpgUrlFromUrlTvg() async throws {
        let (model, _, _) = try make { _ in Self.m3u }
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        model.confirm()
        #expect(model.state.step == .epgUrl)
        #expect(model.state.epgUrl == "http://epg.example/guide.xml")
    }

    @Test func finishPersistsPlaylistChannelsAndEpg() async throws {
        let (model, store, channels) = try make { _ in Self.m3u }
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        model.confirm()
        await model.finishEpg()
        #expect(model.state.step == .done)
        let stored = try store.all()
        #expect(stored.count == 1)
        #expect(stored[0].name == "host.tv")
        #expect(stored[0].epgUrl == "http://epg.example/guide.xml")
        #expect(stored[0].lastUpdatedMs == 42)
        // b.mp4 is now classified as VOD (the import partition), so only the
        // live a.ts lands in channels — VOD no longer pollutes the guide.
        #expect(try channels.channels(playlistId: Int(stored[0].id ?? 0)).count == 1)
    }

    @Test func blankEpgUrlClearsIt() async throws {
        let (model, store, _) = try make { _ in Self.m3u }
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        model.confirm()
        model.setEpgUrl("   ")
        await model.finishEpg()
        #expect(try store.all()[0].epgUrl == nil)
    }

    @Test func invalidEpgUrlBlocksFinishWithError() async throws {
        let (model, store, _) = try make { _ in Self.m3u }
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        model.confirm()
        model.setEpgUrl("not-a-url")
        await model.finishEpg()
        #expect(model.state.step == .epgUrl)
        #expect(model.state.error == .invalidURL)
        #expect(try store.all().isEmpty)
    }

    @Test func pastePlaylistUrlCopiesTheSourceUrl() async throws {
        let (model, _, _) = try make { _ in Self.m3u }
        model.setUrl("http://host.tv/list.m3u ")
        await model.submitUrl()
        model.confirm()
        model.pastePlaylistUrl()
        #expect(model.state.epgUrl == "http://host.tv/list.m3u")
    }

    @Test func backWalksStepsAndLeavesAtTheEnds() async throws {
        let (model, _, _) = try make { _ in Self.m3u }
        model.chooseType(.m3u)
        #expect(model.back())               // urlEntry -> typeChooser
        #expect(model.state.step == .typeChooser)
        #expect(!model.back())              // typeChooser -> leave
        model.setUrl("http://host.tv/list.m3u")
        await model.submitUrl()
        model.confirm()
        #expect(model.back())               // epgUrl -> processed
        #expect(model.state.step == .processed)
        #expect(model.back())               // processed -> urlEntry
        #expect(model.state.step == .urlEntry)
    }
}
