import Testing
@testable import Telly

/// Xtream credential parsing + URL construction — the pure seam every Xtream
/// import/refresh/catch-up path depends on. All hosts are FAKE `example.com`
/// placeholders with `demo`/`demo`, never a real provider.
struct XtreamCredentialsTests {
    private func demo(_ server: String) -> XtreamCredentials? {
        XtreamCredentials.parse(server: server, username: "demo", password: "demo")
    }

    @Test func parsesSchemeHostPortAndDefaultsHttp() {
        #expect(demo("http://example.com:8080")?.base == "http://example.com:8080")
        #expect(demo("example.com:8080")?.base == "http://example.com:8080")
        #expect(demo("https://example.com")?.base == "https://example.com")
        #expect(demo("http://example.com:8080/")?.host == "example.com")
        #expect(demo("http://example.com:8080/")?.port == 8080)
    }

    @Test func rejectsBlankHostOrCredentials() {
        #expect(demo("") == nil)
        #expect(XtreamCredentials.parse(server: "example.com", username: " ", password: "p") == nil)
        #expect(XtreamCredentials.parse(server: "example.com", username: "u", password: "") == nil)
    }

    @Test func buildsApiXmltvAndStreamUrls() {
        let creds = demo("http://example.com:8080")!
        #expect(creds.apiUrl == "http://example.com:8080/player_api.php?username=demo&password=demo")
        #expect(creds.api(action: "get_live_streams")
                == "http://example.com:8080/player_api.php?username=demo&password=demo&action=get_live_streams")
        #expect(creds.xmltvUrl == "http://example.com:8080/xmltv.php?username=demo&password=demo")
        #expect(creds.liveUrl(streamId: 123) == "http://example.com:8080/live/demo/demo/123.ts")
        #expect(creds.movieUrl(streamId: 9, ext: "mkv") == "http://example.com:8080/movie/demo/demo/9.mkv")
    }

    @Test func roundTripsThroughApiUrl() {
        let creds = demo("http://example.com:8080")!
        #expect(XtreamCredentials.fromApiUrl(creds.apiUrl) == creds)
        #expect(XtreamCredentials.isApiUrl(creds.apiUrl))
    }

    @Test func rejectsNonXtreamUrls() {
        #expect(XtreamCredentials.fromApiUrl("http://example.com/get.php?username=demo&password=demo") == nil)
        #expect(!XtreamCredentials.isApiUrl("http://example.com/playlist.m3u"))
    }
}
