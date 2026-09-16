import Foundation
import SWCompression

/// Transparently decompresses an EPG payload before it reaches `XmltvParser`.
/// Providers hand out `guide.xml.gz` / `guide.xml.xz` (or plain XML), so we
/// sniff the leading magic bytes and pick a decoder — gzip or xz — falling back
/// to the raw bytes for plain XML or anything we can't decode. Ported from the
/// Android `CompressedXmltv`; the SWCompression dependency is confined here.
enum CompressedXmltv {
    /// gzip files begin `0x1F 0x8B`.
    private static let gzipMagic: [UInt8] = [0x1F, 0x8B]
    /// xz files begin `0xFD '7' 'z' 'X' 'Z' 0x00`.
    private static let xzMagic: [UInt8] = [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00]

    /// Returns the decompressed bytes, or `data` unchanged when it is empty,
    /// carries no known magic, or fails to decode (never throws / crashes).
    static func decompress(_ data: Data) -> Data {
        guard !data.isEmpty else { return data }
        if hasPrefix(data, gzipMagic) {
            return (try? GzipArchive.unarchive(archive: data)) ?? data
        }
        if hasPrefix(data, xzMagic) {
            return (try? XZArchive.unarchive(archive: data)) ?? data
        }
        return data
    }

    /// True when `data` starts with every byte of `magic`.
    private static func hasPrefix(_ data: Data, _ magic: [UInt8]) -> Bool {
        guard data.count >= magic.count else { return false }
        return Array(data.prefix(magic.count)) == magic
    }
}
