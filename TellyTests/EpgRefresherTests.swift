import Testing
import Foundation
import GRDB
@testable import Telly

/// `EpgRefresher` orchestration against REAL in-memory GRDB stores (as E3's
/// tests do) with a fake `download` closure: only-due filtering, per-source
/// failure swallowing, stamp-iff-any-succeeded, the past trim, and the
/// due-ignoring `refreshAllNow` / `onPlaylistsChanged` hooks.
struct EpgRefresherTests {
    private let now = 1_000_000_000_000
    private let hour = RefreshScheduler.hourMs

    /// Collects `warn` diagnostics so failure paths can be asserted.
    private final class Warnings { var messages: [String] = [] }

    private func makeStores() throws -> (PlaylistStore, ProgramStore) {
        let db = try AppDatabase.makeInMemory()
        return (PlaylistStore(db: db), ProgramStore(db: db))
    }

    @discardableResult
    private func addPlaylist(_ store: PlaylistStore, url: String, epg: String?) throws -> Int64 {
        try store.add(sourceUrl: url, playlist: M3uPlaylist(epgURL: epg, channels: []), name: nil, nowMs: 0)
    }

    private func doc(_ channel: String) -> XmltvDocument {
        XmltvDocument(channels: [], programs: [XmltvProgram(
            channelId: channel, startMs: now, endMs: now + hour,
            details: ProgramDetails(title: "T", subTitle: nil, description: nil,
                                    category: nil, episode: nil))])
    }

    private func downloader(_ map: [String: XmltvDocument],
                            failing: Set<String> = []) -> (String) async throws -> XmltvDocument {
        { url in
            if failing.contains(url) { throw URLError(.badServerResponse) }
            return map[url] ?? XmltvDocument()
        }
    }

    private func stamp(_ store: PlaylistStore, url: String) throws -> Int64 {
        try store.all().first { $0.url == url }?.epgLastUpdatedMs ?? -1
    }

    @Test func refreshDueRefreshesOnlyDuePlaylistsAndSkipsSourceless() async throws {
        let (playlists, programs) = try makeStores()
        try addPlaylist(playlists, url: "due", epg: "e1")
        try addPlaylist(playlists, url: "sourceless", epg: nil)     // due but no sources → skipped
        let freshId = try addPlaylist(playlists, url: "fresh", epg: "e2")
        try playlists.markEpgUpdated(id: freshId, nowMs: Int64(now)) // not due
        let refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader(["e1": doc("c1"), "e2": doc("c2")]), now: { self.now })

        try await refresher.refreshDue()

        #expect(try programs.channelIds() == ["c1"])
    }

    @Test func failedSourceIsSwallowedButPlaylistStampedIfAnotherSucceeds() async throws {
        let (playlists, programs) = try makeStores()
        try addPlaylist(playlists, url: "p", epg: "bad")
        let warnings = Warnings()
        let refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader(["good": doc("c1")], failing: ["bad"]), now: { self.now },
            customSources: { _ in ["good"] }, warn: { warnings.messages.append($0) })

        try await refresher.refreshDue()

        #expect(try programs.channelIds() == ["c1"])
        #expect(try stamp(playlists, url: "p") == Int64(now))
        #expect(warnings.messages.count == 1)
    }

    @Test func allSourcesFailingLeavesPlaylistUnstampedAndStillDue() async throws {
        let (playlists, programs) = try makeStores()
        try addPlaylist(playlists, url: "p", epg: "bad1")
        let warnings = Warnings()
        let refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader([:], failing: ["bad1", "bad2"]), now: { self.now },
            customSources: { _ in ["bad2"] }, warn: { warnings.messages.append($0) })

        try await refresher.refreshDue()

        #expect(try programs.channelIds().isEmpty)
        #expect(try stamp(playlists, url: "p") == 0)   // never stamped → stays due
        #expect(warnings.messages.count == 2)
    }

    @Test func refreshTrimsProgrammesEndedBeforeNowMinusKeepPast() async throws {
        let (playlists, programs) = try makeStores()
        try programs.upsertReplacing(document: XmltvDocument(channels: [], programs: [
            XmltvProgram(channelId: "old", startMs: now - 9 * RefreshScheduler.dayMs,
                         endMs: now - 8 * RefreshScheduler.dayMs,
                         details: ProgramDetails(title: "T", subTitle: nil, description: nil,
                                                 category: nil, episode: nil)),
            XmltvProgram(channelId: "fresh", startMs: now, endMs: now + hour,
                         details: ProgramDetails(title: "T", subTitle: nil, description: nil,
                                                 category: nil, episode: nil))]),
            keepDescriptions: true)
        let refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader([:]), now: { self.now })

        try await refresher.refreshAllNow()   // no playlists, but trim still runs

        #expect(try programs.channelIds() == ["fresh"])
    }

    @Test func refreshAllNowIgnoresDueness() async throws {
        let (playlists, programs) = try makeStores()
        let id = try addPlaylist(playlists, url: "p", epg: "e")
        try playlists.markEpgUpdated(id: id, nowMs: Int64(now))   // fresh → not due
        let refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader(["e": doc("c1")]), now: { self.now })

        try await refresher.refreshAllNow()

        #expect(try programs.channelIds() == ["c1"])
    }

    @Test func customIntervalMakesARecentlyRefreshedPlaylistDue() async throws {
        let (playlists, programs) = try makeStores()
        let id = try addPlaylist(playlists, url: "p", epg: "e")
        try playlists.markEpgUpdated(id: id, nowMs: Int64(now - 2 * hour))   // 2h ago
        var refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader(["e": doc("c1")]), now: { self.now })
        refresher.intervalMs = hour   // due after 1h → the 2h-old playlist refreshes

        try await refresher.refreshDue()

        #expect(try programs.channelIds() == ["c1"])
    }

    @Test func customKeepPastTrimsWithinTheChosenHorizon() async throws {
        let (playlists, programs) = try makeStores()
        try programs.upsertReplacing(document: XmltvDocument(channels: [], programs: [
            XmltvProgram(channelId: "old", startMs: now - 3 * RefreshScheduler.dayMs,
                         endMs: now - 2 * RefreshScheduler.dayMs,
                         details: ProgramDetails(title: "T", subTitle: nil, description: nil,
                                                 category: nil, episode: nil))]),
            keepDescriptions: true)
        var refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader([:]), now: { self.now })
        refresher.keepPastMs = RefreshScheduler.dayMs   // keep 1 day → 2-day-old trimmed

        try await refresher.refreshAllNow()

        #expect(try programs.channelIds().isEmpty)
    }

    @Test func onPlaylistsChangedRefreshesOnlyWhenEnabled() async throws {
        let (playlists, programs) = try makeStores()
        try addPlaylist(playlists, url: "p", epg: "e")
        let refresher = EpgRefresher(
            playlistStore: playlists, programStore: programs,
            download: downloader(["e": doc("c1")]), now: { self.now })

        try await refresher.onPlaylistsChanged(updateOnChange: false)
        #expect(try programs.channelIds().isEmpty)

        try await refresher.onPlaylistsChanged(updateOnChange: true)
        #expect(try programs.channelIds() == ["c1"])
    }
}
