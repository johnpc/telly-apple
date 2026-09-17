import Testing
import Foundation
@testable import Telly

/// `EpgDownloader` glue: the injected `data` closure drives the
/// fetch→decompress→parse pipeline. Plain (uncompressed) XMLTV works because
/// `CompressedXmltv.decompress` passes non-compressed bytes through unchanged.
struct EpgDownloaderTests {
    private let xmltv = """
    <tv>
      <programme channel="a" start="20260913120000 +0000" stop="20260913130000 +0000">
        <title>One</title>
      </programme>
      <programme channel="a" start="20260913130000 +0000" stop="20260913140000 +0000">
        <title>Two</title>
      </programme>
    </tv>
    """

    @Test func downloadParsesPlainXmltvPayload() async throws {
        let payload = Data(xmltv.utf8)
        let downloader = EpgDownloader { _ in payload }
        let document = try await downloader.download(epgUrl: "http://example/guide.xml")
        #expect(document.programs.count == 2)
        #expect(document.programs.map(\.channelId) == ["a", "a"])
    }

    @Test func downloadThrowsOnMalformedUrl() async throws {
        let downloader = EpgDownloader { _ in Data() }
        await #expect(throws: URLError.self) {
            try await downloader.download(epgUrl: "")
        }
    }
}
