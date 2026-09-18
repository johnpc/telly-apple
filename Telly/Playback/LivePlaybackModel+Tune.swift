import Foundation

extension LivePlaybackModel {
    /// Tune a specific channel: swap the engine's stream, arm the keep-frame
    /// grace so the previous frame holds under the zap overlay while the new
    /// stream buffers, and remember it as last-watched. This is Android's
    /// `TuneController` minus the gate / history / catch-up seams (resolveUrl is
    /// the identity here — no UDP proxy in this slice).
    func tune(_ channel: ChannelEntity) {
        if blockGate?.intercept(channel) == true { return }
        current = channel
        keepFrame.onZapTune(at: now())
        engine.load(channel.source.streamUrl, isLive: true)
        persistLastChannel(channel.id)
    }

    /// The heartbeat the screen's timer calls (~5 Hz): expire transient overlays,
    /// fire a settled coalesced zap, and clear the keep-frame once video is live.
    func tick() {
        visibility.resolve(at: now())
        if let delta = pendingZap.resolve(at: now()) { performZap(delta) }
        if engine.state == .reconnecting { keepFrame.onReconnect(at: now()) }
        if engine.state == .playing { keepFrame.onPlaying() }
    }

    /// Show the compact zap overlay, auto-hiding after the zap timeout.
    func showZapInfo() {
        visibility.showAutoHiding(.zapInfo, timeoutMs: timeouts.zapMs, at: now())
    }

    /// Turn a settled net delta into an actual neighbour tune (net-zero = no-op).
    func performZap(_ delta: Int) {
        guard delta != 0 else { return }
        guard let next = ChannelZapper.neighbour(channels, current: current, delta: delta) else { return }
        tune(next)
    }

    /// Tear the engine down when the screen goes away.
    func close() {
        engine.stop()
        engine.release()
    }
}
