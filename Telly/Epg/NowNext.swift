import Foundation

/// The programme airing now and the one after it on a single channel.
struct NowNext: Equatable {
    var now: ProgramEntity?
    var next: ProgramEntity?
}

/// Pure fold from a window of programmes to per-channel now/next.
enum NowNextResolver {
    /// `programs` must be ordered by (channelTvgId, startMs) and contain only
    /// rows ending after `atMs` — exactly what the airing/upcoming query emits.
    /// Channels without matching rows are absent from the result.
    static func resolve(_ programs: [ProgramEntity], atMs: Int) -> [String: NowNext] {
        Dictionary(grouping: programs, by: { $0.channelTvgId }).mapValues { channelPrograms in
            NowNext(
                now: channelPrograms.first { $0.startMs <= atMs && $0.endMs > atMs },
                next: channelPrograms.first { $0.startMs > atMs })
        }
    }
}
