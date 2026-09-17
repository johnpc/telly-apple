import Testing
@testable import Telly

/// The pure backup codec: a populated payload round-trips through JSON
/// unchanged, the version field is carried, unknown keys are ignored
/// (forward-compat) and malformed input decodes to nil rather than throwing.
struct BackupCodecTests {
    private func payload() -> BackupPayload {
        BackupPayload(
            settings: ["use24hClock": "false", "epgRefreshHours": "12"],
            playlists: [BackupPlaylist(name: "A", url: "http://127.0.0.1:8000/a.m3u",
                                       epgUrl: "http://127.0.0.1:8000/epg.xml"),
                        BackupPlaylist(name: "B", url: "http://127.0.0.1:8000/b.m3u", epgUrl: nil)],
            epgSources: [BackupEpgSource(playlistUrl: "http://127.0.0.1:8000/a.m3u",
                                         url: "http://127.0.0.1:8000/extra.xml")])
    }

    @Test func roundTripIsIdentity() {
        let original = payload()
        #expect(BackupCodec.decode(BackupCodec.encode(original)) == original)
    }

    @Test func versionFieldPresent() {
        let json = BackupCodec.encode(payload())
        #expect(json.contains("\"version\" : 1"))
        #expect(BackupCodec.decode(json)?.version == 1)
    }

    @Test func unknownKeysIgnored() {
        let json = """
        {"version":1,"settings":{},"playlists":[],"epgSources":[],"futureField":42}
        """
        #expect(BackupCodec.decode(json)?.playlists.isEmpty == true)
    }

    @Test func malformedDecodesToNil() {
        #expect(BackupCodec.decode("not json at all") == nil)
        #expect(BackupCodec.decode("{\"settings\":{}}") == nil)
    }
}
