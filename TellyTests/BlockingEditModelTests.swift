import Testing
import GRDB
@testable import Telly

/// The bulk Manage-Blocking editor model: lists every channel and persists a
/// toggled blocked flag, but only once the parental PIN gate (when active) is
/// unlocked. Sibling of ``VisibilityEditModelTests``.
@MainActor
struct BlockingEditModelTests {
    private func seed() throws -> ChannelStore {
        let db = try AppDatabase.makeInMemory()
        let playlists = PlaylistStore(db: db)
        let list = M3uPlaylist(channels: [m("A"), m("B"), m("C")])
        _ = try playlists.add(sourceUrl: "u", playlist: list, name: nil, nowMs: 0)
        return ChannelStore(db: db)
    }

    private func m(_ name: String) -> M3uChannel {
        M3uChannel(title: name, streamURL: "http://x/\(name)", tvgID: name, tvgName: nil,
                   tvgLogo: nil, groupTitle: "Live", catchup: nil, catchupSource: nil, catchupDays: nil)
    }

    /// A parental store over fresh in-memory backings, optionally with a PIN set
    /// and enforcement enabled (the gated case).
    private func parental(gated: Bool) -> ParentalStore {
        let store = ParentalStore(secret: InMemorySecretStore(), backing: InMemoryKeyValueStore())
        if gated {
            store.set(pin: "1234")
            store.isEnabled = true
        }
        return store
    }

    @Test func listsEveryChannelAndStartsUnlockedWithoutParental() throws {
        let model = BlockingEditModel(store: try seed(), parental: parental(gated: false))
        model.load()
        #expect(model.locked == false)
        #expect(model.channels.map(\.source.name) == ["A", "B", "C"])
    }

    @Test func toggleBlockedPersistsAndReloads() throws {
        let store = try seed()
        let model = BlockingEditModel(store: store, parental: parental(gated: false))
        model.load()
        let a = try #require(model.channels.first { $0.source.name == "A" })
        model.toggleBlocked(a)
        #expect(model.channels.first { $0.source.name == "A" }?.flags.blocked == true)
        #expect(try store.allChannels().first { $0.source.name == "A" }?.flags.blocked == true)
    }

    @Test func lockedGateBlocksTogglesUntilUnlocked() throws {
        let store = try seed()
        let model = BlockingEditModel(store: store, parental: parental(gated: true))
        model.load()
        #expect(model.locked == true)
        let a = try #require(model.channels.first { $0.source.name == "A" })
        model.toggleBlocked(a)                                   // no-op while locked
        #expect(try store.allChannels().first { $0.source.name == "A" }?.flags.blocked == false)
    }

    @Test func unlockWithCorrectPinOpensEditorWrongPinStaysLocked() throws {
        let model = BlockingEditModel(store: try seed(), parental: parental(gated: true))
        #expect(model.unlock(pin: "0000") == false)              // wrong PIN
        #expect(model.locked == true)
        #expect(model.unlock(pin: "1234") == true)               // correct PIN
        #expect(model.locked == false)
    }
}
