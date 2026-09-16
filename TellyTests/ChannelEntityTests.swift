import Testing
@testable import Telly

/// Unit coverage for the channel row's derived display fields.
struct ChannelEntityTests {

    private func channel(name: String, tvgId: String? = nil) -> ChannelEntity {
        ChannelEntity(playlistId: 1, number: 1, sortIndex: 0,
                      source: ChannelSource(name: name, streamUrl: "u", tvgId: tvgId))
    }

    @Test func displayNamePrefersNonBlankCustomName() {
        var row = channel(name: "Playlist Name")
        #expect(row.displayName == "Playlist Name")
        row.overrides.customName = "   "
        #expect(row.displayName == "Playlist Name")   // blank override ignored
        row.overrides.customName = "Custom"
        #expect(row.displayName == "Custom")
    }

    @Test func epgIdPrefersOverrideElseTvgId() {
        var row = channel(name: "N", tvgId: "auto")
        #expect(row.epgId == "auto")
        row.overrides.epgOverride = "manual"
        #expect(row.epgId == "manual")
        #expect(channel(name: "N").epgId == nil)
    }
}
