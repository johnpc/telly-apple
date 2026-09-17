import Foundation
@testable import Telly

/// A `PlayerEngine` test double: records every `load`/`stop`/`release` call and
/// exposes a settable `state` so the orchestrator's keep-frame and tick logic
/// can be driven deterministically without VLCKit.
@MainActor
final class FakePlayerEngine: PlayerEngine {
    var state: PlayerState = .idle
    var video: VideoDetails?
    var paused = false
    var tracks: TrackFacade = NoTracks()

    private(set) var loaded: [String] = []
    private(set) var stopCount = 0
    private(set) var releaseCount = 0
    private(set) var muted = false

    func load(_ streamUrl: String) { loaded.append(streamUrl) }
    func stop() { stopCount += 1 }
    func release() { releaseCount += 1 }
    func setMuted(_ m: Bool) { muted = m }
}
