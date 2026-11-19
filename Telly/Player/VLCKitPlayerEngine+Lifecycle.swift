import Foundation
import VLCKitSPM

/// Load / stop / release for the real engine, split from the primary adapter to
/// keep it within the source-line budget. `stop()` runs libVLC's synchronous stop
/// on the serial `control` queue; this file also tracks when that stop has
/// RETURNED, because until then the main actor must stay off libVLC's input lock
/// (`vlcQuiescent`): the track facade is detached for the duration and re-wired
/// once a later `load()` is in effect. Untestable device glue by nature.
extension VLCKitPlayerEngine {
    func load(_ streamUrl: String, isLive: Bool) {
        retry?.cancel()
        reducer.isLive = isLive
        reducer.onLoad(); state = reducer.state
        guard let url = URL(string: DemoContent.playableUrl(for: streamUrl)) else { return }
        let media = VLCMedia(url: url)
        BufferPolicy.mediaOptions(for: buffer).forEach { media.addOption($0) }
        tracksWanted = true
        if vlcQuiescent { trackFacade.player = player }
        let player = self.player
        control.async { player.media = media; player.play() }
    }

    func stop() {
        retry?.cancel()
        tearDown()
        reducer.onStopped(); state = reducer.state
    }

    func release() {
        retry?.cancel()
        player.delegate = nil
        player.drawable = nil
        tearDown()
    }

    /// Stops libVLC on `control` (in order after any pending load) and counts the
    /// stop as in flight until it has returned; `tornDown()` then runs on main.
    private func tearDown() {
        teardowns += 1
        tracksWanted = false
        trackFacade.player = nil
        let player = self.player
        control.async {
            player.stop()
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated { self?.tornDown() }
            }
        }
    }

    private func tornDown() {
        teardowns -= 1
        if vlcQuiescent && tracksWanted { trackFacade.player = player }
    }
}
