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
    var state: PlayerState = .idle
    private(set) var video: VideoDetails?
    private(set) var paused = false
    var tracks: TrackFacade { trackFacade }

    let trackFacade = VlcTrackFacade()
    let player = VLCMediaPlayer()
    private let proxy = VlcDelegateProxy()
    var reducer = PlaybackReducer()
    var retry: Task<Void, Never>?
    let buffer: BufferSize
    /// libVLC `stop()`s still running on `control` (see `+Lifecycle`). While one is
    /// in flight the main actor must not call a libVLC getter that takes the input
    /// lock (tracks, time, seekable, video size, vout geometry): `stop()` holds that
    /// lock while it joins the input thread, whose vout teardown `dispatch_sync`s
    /// onto main, so a main-side read deadlocks the whole app (CI run 44576307888:
    /// 150 s hang after the close tap). Every such read checks `vlcQuiescent`.
    var teardowns = 0
    /// A `load()` since the last `stop()` wants the track facade wired to libVLC.
    var tracksWanted = false
    var vlcQuiescent: Bool { teardowns == 0 }
    /// EVERY libVLC control call (media swap, play, stop, pause, seek) runs here, in
    /// order, off the main actor: `stop()` on a live network stream can block for
    /// seconds while the demuxer tears down, and the UI must never wait on it
    /// (closing the player froze the whole app for a minute under host load).
    /// libVLC is thread-safe; only the `drawable` (a UIView) stays on main.
    let control = DispatchQueue(label: "com.johncorser.telly.vlc-control", qos: .userInitiated)

    /// `buffer` falls back to the persisted setting at mint time (`nil`), so
    /// EVERY engine (live, multiview tiles, VOD, catch-up) honors the user's
    /// "Buffer size" pick; the composition root passes its injected store's
    /// value explicitly. A changed setting applies on the next engine mint.
    init(buffer: BufferSize? = nil) {
        self.buffer = buffer ?? SettingsStore.standard.bufferSize
        proxy.onStateChange = { [weak self] in self?.onStateChange() }
        player.delegate = proxy
    }

    /// The UIView the surface hands us for VLC to render into.
    var drawable: UIView? {
        get { player.drawable as? UIView }
        set { player.drawable = newValue }
    }

    private func onStateChange() {
        // Events emitted by a stop() still running on `control` (stopped / ended /
        // error) carry nothing the reducer has not already applied in stop().
        guard vlcQuiescent else { return }
        let vlc = Self.mapped(player.state)
        switch vlc {
        case .esAdded, .playing: paused = false; captureVideo()
        case .paused: paused = true
        default: break
        }
        if let effect = reducer.onVlcState(vlc) { perform(effect) }
        state = reducer.state
    }

    private func perform(_ effect: PlaybackReducer.ErrorEffect) {
        guard case let .reconnect(delayMs) = effect else { return }
        retry = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            guard !Task.isCancelled, let self else { return }
            let player = self.player
            self.control.async { player.play() }
        }
    }

    private func captureVideo() {
        guard vlcQuiescent else { return }  // `videoSize` takes libVLC's input lock
        let size = player.videoSize
        video = VideoDetails(width: Int(size.width), height: Int(size.height),
                             frameRate: 0, audioChannels: 0)
    }
}
