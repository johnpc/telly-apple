import Testing
@testable import Telly

/// Host-name derivation for a custom EPG source's display name — scheme/path/
/// port stripped, blank/host-less input passed through unchanged.
struct EpgSourceTests {
    @Test func hostStripsSchemePathAndPort() {
        #expect(EpgSource.host("http://127.0.0.1:8000/epg.xml") == "127.0.0.1")
    }

    @Test func hostKeepsBareHost() {
        #expect(EpgSource.host("https://host/x") == "host")
    }

    @Test func hostWithoutSchemeReturnsInput() {
        #expect(EpgSource.host("epg.example") == "epg.example")
    }

    @Test func blankReturnsInput() {
        #expect(EpgSource.host("") == "")
    }

    @Test func nameDerivesFromUrl() {
        let source = EpgSource(id: 7, playlistUrl: "http://127.0.0.1:8000/a/playlist.m3u",
                               url: "http://127.0.0.1:8000/epg.xml")
        #expect(source.name == "127.0.0.1")
    }
}
