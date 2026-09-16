import Foundation

/// TiviMate's playlist classification (device-verified, ported from Android):
/// entries whose stream URL carries a video-file extension are VOD "Movies";
/// streams (.ts/.m3u8/no extension) are live channels. One source of truth —
/// the wizard summary and the importer both dispatch on `isVod`.
enum VodClassifier {
    private static let vodExtensions: Set<String> = ["mp4", "mkv", "avi", "mov"]

    static func isVod(_ streamUrl: String) -> Bool {
        let beforeQuery = streamUrl.split(separator: "?", maxSplits: 1)[0]
        guard let dot = beforeQuery.lastIndex(of: ".") else { return false }
        let ext = beforeQuery[beforeQuery.index(after: dot)...].lowercased()
        return vodExtensions.contains(ext)
    }
}
