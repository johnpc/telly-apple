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
    var tracks: TrackFacade { trackFacade }

    private let trackFacade = VlcTrackFacade()
    let player = VLCMediaPlayer()
    private let proxy = VlcDelegateProxy()
    private var reducer = PlaybackReducer()
    private var retry: Task<Void, Never>?

    init() {
        proxy.onStateChange = { [weak self] in self?.onStateChange() }
        player.delegate = proxy
        trackFacade.player = player
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

    private func onStateChange() {
        let vlc = Self.mapped(player.state)
        switch vlc {
        case .esAdded, .playing: paused = false; captureVideo()
        case .paused: paused = true
        default: break
        }
        if let effect = reducer.onVlcState(vlc) { perform(effect) }
        state = reducer.state
    }

    /// Thin, untestable translation of VLCKit's ObjC state enum into our own
    /// ``VlcPlaybackState`` mirror — the only place that touches VLCKit types.
    /// All decision logic lives in the pure ``PlaybackReducer/onVlcState(_:)``.
    private static func mapped(_ state: VLCMediaPlayerState) -> VlcPlaybackState {
        switch state {
        case .opening: return .opening
        case .buffering: return .buffering
        case .esAdded: return .esAdded
        case .playing: return .playing
        case .paused: return .paused
        case .stopped: return .stopped
        case .ended: return .ended
        case .error: return .error
        @unknown default: return .buffering
        }
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
