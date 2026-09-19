import Testing
import GRDB
@testable import Telly

/// The Playlists management model against a real in-memory DB + a fake fetcher:
/// list/load, manual update (re-import + reload), URL change (re-keys settings +
/// EPG sources, failure keeps old), delete cascade, group derivation + toggle,
/// per-playlist interval/on-start, and custom EPG-source add/edit/remove.
@MainActor
struct PlaylistsSettingsModelTests {
    private let a = "http://127.0.0.1:8000/a/playlist.m3u"
    private let b = "http://127.0.0.1:8000/b/playlist.m3u"
    private let epg = "http://127.0.0.1:8000/epg.xml"

    private static func m3u(_ names: [String], epg: String? = nil, groups: [String] = ["News"]) -> String {
        var text = epg.map { "#EXTM3U url-tvg=\"\($0)\"\n" } ?? "#EXTM3U\n"
        for (index, name) in names.enumerated() {
            let group = groups[index % groups.count]
            text += "#EXTINF:-1 tvg-id=\"\(name)\" group-title=\"\(group)\",\(name)\n"
            text += "http://127.0.0.1:8000/\(name)\n"
        }
        return text
    }

    private struct Rig {
        let model: PlaylistsSettingsModel
        let store: PlaylistStore
        let epgStore: EpgSourceStore
        let channels: ChannelStore
        let settings: SettingsStore
        let reloads: () -> Int
        let epgRefreshes: () -> Int
    }

    private final class Counter { var value = 0 }

    private func rig(fetch: @escaping (String) async throws -> String = { _ in m3u(["A"]) }) throws -> Rig {
        let db = try AppDatabase.makeInMemory()
        let store = PlaylistStore(db: db)
        let epgStore = EpgSourceStore(db: db)
        let channels = ChannelStore(db: db)
        let settings = SettingsStore(backing: InMemoryKeyValueStore())
        var count = 0
        let epg = Counter()
        let model = PlaylistsSettingsModel(
            playlistStore: store, epgSourceStore: epgStore, channelStore: channels,
            settings: settings,
            updater: PlaylistUpdater(fetch: fetch, store: store, now: { 1 }),
            makeAddModel: { AddPlaylistModel(fetch: fetch, store: store, now: { 1 }) },
            refreshEpg: { epg.value += 1 }, reload: { count += 1 })
        return Rig(model: model, store: store, epgStore: epgStore, channels: channels,
                   settings: settings, reloads: { count }, epgRefreshes: { epg.value })
    }

    @discardableResult
    private func seedA(_ r: Rig, names: [String] = ["A"], epg: String? = nil,
                       groups: [String] = ["News"]) throws -> Int64 {
        let id = try r.store.add(sourceUrl: a, playlist: M3uParser.parse(Self.m3u(names, epg: epg, groups: groups)),
                                 name: "List A", nowMs: 1)
        r.model.load()
        return id
    }

    @Test func loadPublishesStoredPlaylists() throws {
        let r = try rig()
        try seedA(r)
        #expect(r.model.playlists.map(\.url) == [a])
        #expect(r.model.playlists.first?.name == "List A")
    }

    @Test func updateNowReimportsChannelsAndReloads() async throws {
        let r = try rig(fetch: { _ in Self.m3u(["A", "B", "C"]) })
        let id = try seedA(r)
        await r.model.updateNow(a)
        #expect(try r.channels.channels(playlistId: Int(id)).count == 3)
        #expect(r.reloads() >= 1)
    }

    @Test func updateAllRefreshesEveryPlaylistAndReloads() async throws {
        let r = try rig(fetch: { _ in Self.m3u(["X", "Y"]) })
        let id = try seedA(r)
        await r.model.updateAll()
        #expect(try r.channels.channels(playlistId: Int(id)).count == 2)
        #expect(r.reloads() >= 1)
    }

    @Test func updateTriggersEpgRefreshWhenToggleOn() async throws {
        let r = try rig()
        try seedA(r)
        r.settings.updateOnPlaylistsChange = true
        await r.model.updateNow(a)
        #expect(r.epgRefreshes() == 1)
        await r.model.updateAll()
        #expect(r.epgRefreshes() == 2)
    }

    @Test func updateSkipsEpgRefreshWhenToggleOff() async throws {
        let r = try rig()
        try seedA(r)
        await r.model.updateNow(a)          // toggle defaults off
        await r.model.updateAll()
        #expect(r.epgRefreshes() == 0)
    }

    @Test func refreshEpgNowAlwaysRefreshes() async throws {
        let r = try rig()
        await r.model.refreshEpgNow()       // unconditional, even with toggle off
        #expect(r.epgRefreshes() == 1)
    }

    @Test func changeUrlSuccessRekeysSettingsAndSources() throws {
        let r = try rig()
        try seedA(r, epg: epg, groups: ["News"])
        r.settings.setUpdateInterval(url: a, 12)
        r.settings.setGroupEnabled(url: a, group: "News", false)
        try r.epgStore.add(playlistUrl: a, url: epg, nowMs: 1)
        #expect(r.model.changeUrl(old: a, new: b) == true)
        #expect(r.model.playlists.map(\.url) == [b])
        #expect(r.settings.updateInterval(url: b) == 12)
        #expect(r.settings.groupEnabled(url: b, group: "News") == false)
        #expect(r.settings.updateInterval(url: a) == 0)            // old key purged → default
        #expect(try r.epgStore.forPlaylist(a).isEmpty)
        #expect(try r.epgStore.forPlaylist(b).map(\.url) == [epg])
    }

    @Test func changeUrlInvalidUrlChangesNothing() throws {
        let r = try rig()
        try seedA(r)
        #expect(r.model.changeUrl(old: a, new: "ftp://nope") == false)
        #expect(r.model.playlists.map(\.url) == [a])
    }

    @Test func changeUrlToTakenUrlFails() throws {
        let r = try rig()
        try seedA(r)
        _ = try r.store.add(sourceUrl: b, playlist: M3uParser.parse(Self.m3u(["Z"])), name: nil, nowMs: 1)
        r.model.load()
        #expect(r.model.changeUrl(old: a, new: b) == false)
    }

    @Test func deleteCascadesSourcesAndSettings() throws {
        let r = try rig()
        try seedA(r, groups: ["News"])
        r.settings.setUpdateInterval(url: a, 8)
        r.settings.setGroupEnabled(url: a, group: "News", false)
        try r.epgStore.add(playlistUrl: a, url: epg, nowMs: 1)
        r.model.delete(a)
        #expect(r.model.playlists.isEmpty)
        #expect(try r.epgStore.forPlaylist(a).isEmpty)
        #expect(r.settings.updateInterval(url: a) == 0)
        #expect(r.settings.groupEnabled(url: a, group: "News") == true)  // purged → default
        #expect(r.reloads() >= 1)
    }

    @Test func groupNamesDerivedFromChannels() throws {
        let r = try rig()
        try seedA(r, names: ["A", "B", "C"], groups: ["News", "Movies"])
        #expect(r.model.groupNames(for: a) == ["News", "Movies"])
    }

    @Test func groupNamesForUnknownUrlIsEmpty() throws {
        let r = try rig()
        try seedA(r)
        #expect(r.model.groupNames(for: b).isEmpty)
    }

    @Test func setGroupEnabledPersists() throws {
        let r = try rig()
        try seedA(r)
        r.model.setGroupEnabled(url: a, group: "News", false)
        #expect(r.model.groupEnabled(url: a, group: "News") == false)
    }

    @Test func intervalAndOnStartReadWrite() throws {
        let r = try rig()
        try seedA(r)
        r.model.setInterval(for: a, 8)
        r.model.setOnStart(for: a, true)
        #expect(r.model.interval(for: a) == 8)
        #expect(r.model.onStart(for: a) == true)
    }

    @Test func autoEpgUrlReflectsPlaylist() throws {
        let r = try rig()
        try seedA(r, epg: epg)
        #expect(r.model.autoEpgUrl(for: a) == epg)
    }

    @Test func addSourceValidatesPersistsAndDedupes() throws {
        let r = try rig()
        try seedA(r)
        #expect(r.model.addSource(playlistUrl: a, url: epg) == true)
        #expect(r.model.addSource(playlistUrl: a, url: "not a url") == false)
        #expect(r.model.sources(for: a).map(\.url) == [epg])
    }

    @Test func setSourceUrlAndRemove() throws {
        let r = try rig()
        try seedA(r)
        _ = r.model.addSource(playlistUrl: a, url: epg)
        let id = try #require(r.model.sources(for: a).first?.id)
        #expect(r.model.setSourceUrl(id: id, url: "bad") == false)
        #expect(r.model.setSourceUrl(id: id, url: "http://127.0.0.1:8000/new.xml") == true)
        #expect(r.model.sources(for: a).map(\.url) == ["http://127.0.0.1:8000/new.xml"])
        r.model.removeSource(id: id)
        #expect(r.model.sources(for: a).isEmpty)
    }

    @Test func makeAddModelReusesTheWizard() throws {
        let r = try rig()
        #expect(r.model.makeAddModel().state.step == .typeChooser)
    }
}
