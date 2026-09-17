import Foundation
@testable import Telly

/// A `PlayerEngine` test double: records every `load`/`stop`/`release`/`seek`
/// call and exposes a settable `state`/`paused`/`positionMs` so the
/// orchestrator's keep-frame, tick and transport logic can be driven
/// deterministically without VLCKit. Position moves ONLY on an explicit
/// `seek`/set — no wall clock — so seek and hop tests stay assertable.
@MainActor
final class FakePlayerEngine: PlayerEngine {
    var state: PlayerState = .idle
    var video: VideoDetails?
    var paused = false
    var positionMs = 0
    var durationMs = 0
    var tracks: TrackFacade = NoTracks()

    private(set) var loaded: [String] = []
    private(set) var stopCount = 0
    private(set) var releaseCount = 0
    private(set) var muted = false
    private(set) var seeks: [Int] = []

    func load(_ streamUrl: String) { loaded.append(streamUrl) }
    func stop() { stopCount += 1 }
    func release() { releaseCount += 1 }
    func pause() { paused = true }
    func resume() { paused = false }
    func seek(toMs m: Int) { positionMs = m; seeks.append(m) }
    func setMuted(_ m: Bool) { muted = m }
}
