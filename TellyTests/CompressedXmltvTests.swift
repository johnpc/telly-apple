import Foundation
import Testing
import SWCompression
@testable import Telly

/// Branch coverage for the gzip / xz / plain sniffing decompressor.
struct CompressedXmltvTests {
    private let xml = "<tv></tv>"

    @Test func gzipRoundTrips() throws {
        let original = Data(xml.utf8)
        let gz = try GzipArchive.archive(data: original)
        #expect(Array(gz.prefix(2)) == [0x1F, 0x8B])
        #expect(CompressedXmltv.decompress(gz) == original)
    }

    @Test func xzFixtureDecompresses() throws {
        let xz = try #require(Data(base64Encoded: Self.xzFixture))
        #expect(xz.prefix(6) == Data([0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00]))
        #expect(CompressedXmltv.decompress(xz) == Data(xml.utf8))
    }

    @Test func plainBytesPassThrough() {
        let plain = Data(xml.utf8)
        #expect(CompressedXmltv.decompress(plain) == plain)
    }

    @Test func emptyStaysEmpty() {
        #expect(CompressedXmltv.decompress(Data()) == Data())
    }

    @Test func malformedGzipFallsBackToInput() {
        let broken = Data([0x1F, 0x8B, 0x08, 0x00, 0x99, 0x42])
        #expect(CompressedXmltv.decompress(broken) == broken)
    }

    // `printf '<tv></tv>' | xz | base64` — committed because SWCompression can
    // archive gzip but NOT xz, so we decode a real xz stream in-test.
    private static let xzFixture =
        "/Td6WFoAAATm1rRGBMANCSEBFgAAAAAAAAAAAF9PM+QBAAg8dHY+PC90dj4AAAAAesc7Bodx6EsAASkJZJIcHR+2830BAAAAAARZWg=="
}
