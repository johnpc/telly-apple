import Foundation
import UIKit
import VLCKitSPM

/// The real `PlayerEngine` — a thin adapter over `VLCMediaPlayer`. All decision
/// logic lives in the tested ``PlaybackReducer``; this file only translates VLC
/// state notifications into reducer calls, mirrors the reducer's state into an
/// observable property, and performs the reconnect effect. Untestable device
/// glue by nature, kept deliberately minimal.
@MainActor
@Observable
final class VLCKitPlayerEngine: PlayerEngine {
    private(set) var state: PlayerState = .idle
    private(set) var video: VideoDetails?
    private(set) var paused = false
    let tracks: TrackFacade = NoTracks()

    private let player = VLCMediaPlayer()
    private let proxy = VlcDelegateProxy()
    private var reducer = PlaybackReducer()
    private var retry: Task<Void, Never>?

    init() {
        proxy.onStateChange = { [weak self] in self?.onStateChange() }
        player.delegate = proxy
    }

    /// The UIView the surface hands us for VLC to render into.
    var drawable: UIView? {
        get { player.drawable as? UIView }
        set { player.drawable = newValue }
    }

    func load(_ streamUrl: String) {
        retry?.cancel()
        reducer.onLoad(); state = reducer.state
        guard let url = URL(string: streamUrl) else { return }
        player.media = VLCMedia(url: url)
        player.play()
    }

    func stop() {
        retry?.cancel()
        player.stop()
        reducer.onStopped(); state = reducer.state
    }

    func release() {
        retry?.cancel()
        player.stop()
        player.delegate = nil
        player.drawable = nil
    }

    func setMuted(_ muted: Bool) { player.audio?.isMuted = muted }
    func pause() { player.pause(); paused = true }
    func resume() { player.play(); paused = false }
    func positionMs() -> Int { Int(player.time.intValue) }
    func seekTo(_ positionMs: Int) { player.time = VLCTime(int: Int32(positionMs)) }

    private func onStateChange() {
        switch player.state {
        case .opening, .buffering: reducer.onBuffering()
        case .playing: reducer.onPlaying(); paused = false; captureVideo()
        case .paused: paused = true
        case .ended: reducer.onEnded()
        case .error: perform(reducer.onError("Playback failed"))
        default: break
        }
        state = reducer.state
    }

    private func perform(_ effect: PlaybackReducer.ErrorEffect) {
        guard case let .reconnect(delayMs) = effect else { return }
        retry = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            guard !Task.isCancelled, let self else { return }
            self.player.play()
        }
    }

    private func captureVideo() {
        let size = player.videoSize
        video = VideoDetails(width: Int(size.width), height: Int(size.height),
                             frameRate: 0, audioChannels: 0)
    }
}
