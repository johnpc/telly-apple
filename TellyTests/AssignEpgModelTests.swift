import Testing
import GRDB
@testable import Telly

/// The Assign-EPG models over an in-memory DB: ``EpgAssignmentModel`` lists every
/// channel and vends per-row ``AssignEpgModel``s whose EPG-id options come from
/// the seeded programmes, and whose ``AssignEpgModel/select(_:)`` persists +
/// re-marks the chosen override (and clears it back to Auto).
@MainActor
struct AssignEpgModelTests {
    private func seed() throws -> (ChannelStore, ProgramStore) {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A"), m("B")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        let programs = ProgramStore(db: db)
        try programs.upsertReplacing(
            document: XmltvDocument(channels: [], programs: [prog("bbc"), prog("cnn")]),
            keepDescriptions: true)
        return (ChannelStore(db: db), programs)
    }

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://127.0.0.1:8000/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    private func prog(_ channel: String) -> XmltvProgram {
        XmltvProgram(channelId: channel, startMs: 0, endMs: 100,
                     details: ProgramDetails(title: "T", subTitle: nil, description: nil,
                                             category: nil, episode: nil))
    }

    @Test func entryModelListsChannelsAndVendsPickerWithSeededIds() throws {
        let (channelStore, programStore) = try seed()
        let entry = EpgAssignmentModel(store: channelStore, programStore: programStore)
        entry.load()
        #expect(entry.channels.map(\.source.name) == ["A", "B"])
        let a = try #require(entry.channels.first)
        let picker = entry.assignModel(for: a)
        picker.load()
        #expect(picker.epgIds == ["bbc", "cnn"])                 // sorted distinct ids with data
        #expect(picker.rows.map(\.id) == [nil, "bbc", "cnn"])
        #expect(picker.rows[0].selected == true)                 // Auto selected initially
    }

    @Test func selectPersistsOverrideAndReMarksSelection() throws {
        let (channelStore, programStore) = try seed()
        let a = try #require(try channelStore.allChannels().first)
        let picker = AssignEpgModel(store: channelStore, programStore: programStore, channel: a)
        picker.load()
        picker.select("cnn")
        #expect(picker.channel.overrides.epgOverride == "cnn")
        #expect(picker.rows.first { $0.id == "cnn" }?.selected == true)
        #expect(try channelStore.allChannels().first { $0.id == a.id }?.overrides.epgOverride == "cnn")
    }

    @Test func selectNilClearsOverrideBackToAuto() throws {
        let (channelStore, programStore) = try seed()
        let a = try #require(try channelStore.allChannels().first)
        let picker = AssignEpgModel(store: channelStore, programStore: programStore, channel: a)
        picker.select("bbc")
        picker.select(nil)
        #expect(picker.channel.overrides.epgOverride == nil)
        #expect(picker.rows[0].selected == true)                 // Auto re-selected
        #expect(try channelStore.allChannels().first { $0.id == a.id }?.overrides.epgOverride == nil)
    }
}
