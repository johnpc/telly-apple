import Foundation

extension LivePlaybackModel {
    /// Tune a specific channel: swap the engine's stream, arm the keep-frame
    /// grace so the previous frame holds under the zap overlay while the new
    /// stream buffers, and remember it as last-watched. This is Android's
    /// `TuneController` minus the gate / history / catch-up seams (resolveUrl is
    /// the identity here — no UDP proxy in this slice).
    func tune(_ channel: ChannelEntity) {
        current = channel
        keepFrame.onZapTune(at: now())
        engine.load(channel.source.streamUrl)
        persistLastChannel(channel.id)
    }

    /// The heartbeat the screen's timer calls (~5 Hz): expire transient overlays,
    /// fire a settled coalesced zap, and clear the keep-frame once video is live.
    func tick() {
        visibility.resolve(at: now())
        if let delta = pendingZap.resolve(at: now()) { performZap(delta) }
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
}

#if DEBUG
extension LivePlaybackModel {
    /// DEBUG screenshot hook: pin the zap overlay open (sticky, no deadline, with
    /// the frame held) so the tick loop never hides it — used by the tvOS
    /// overlay-proof launch path (`-tellyOverlay zap`).
    func debugPresentZapOverlay() {
        debugHoldFrame = true
        visibility.set(.zapInfo)
    }

    /// DEBUG screenshot hook: pin the info overlay open (sticky, no deadline,
    /// frame held so no spinner) for the `-tellyOverlay info` proof.
    func debugPresentInfoOverlay() {
        debugHoldFrame = true
        visibility.set(.info)
    }

    /// DEBUG screenshot hook: pin the quick-bar open (sticky, frame held) for the
    /// `-tellyOverlay quickBar` proof.
    func debugPresentQuickBarOverlay() {
        debugHoldFrame = true
        visibility.set(.quickBar)
    }

    /// DEBUG screenshot hook: pin the channel panel open (sticky, frame held) for
    /// the `-tellyOverlay panel` proof.
    func debugPresentPanelOverlay() {
        debugHoldFrame = true
        visibility.set(.panel)
    }

    /// DEBUG screenshot hook: pin a track picker open over the quick-bar with the
    /// canned fixture snapshot (`-tellyOverlay trackAudio|trackSubtitles`).
    func debugPresentTrackPicker(_ kind: TrackPickerKind) {
        debugHoldFrame = true
        debugSnapshot = DebugLaunch.trackFixtureSnapshot()
        activePicker = kind
        visibility.set(.pushed(back: .quickBar))
    }

    /// DEBUG screenshot hook: deliver a real remote `key` through ``onKey(_:)`` so
    /// the resolved command honours the model's captured ``keymap``, then pin the
    /// resulting overlay (frame held, no deadline) so the tick loop can't hide it
    /// before capture — the keymap-remap proof (`-tellyKeymapUpDown switch`).
    func debugApplyKey(_ key: PlaybackKey) {
        debugHoldFrame = true
        onKey(key)
        visibility.set(visibility.overlay)
    }
}
#endif
