import Foundation

extension LivePlaybackModel {
    /// Handle a remote / D-pad key: keep any transient overlay alive, resolve the
    /// semantic command via the pure ``PlaybackKeyPolicy``, then run it. Returns
    /// whether the key was bound in the active context so the platform layer can
    /// decide whether to consume the event.
    @discardableResult
    func onKey(_ key: PlaybackKey) -> Bool {
        visibility.keepAlive(at: now())
        let command = PlaybackKeyPolicy.command(overlay: visibility.overlay, key: key, keymap: keymap)
        execute(command)
        return command != .nothing
    }

    /// Run one semantic command — the Apple port of Android's `PlaybackCommands`
    /// executor, minus the trimmed slices (block-PIN, catch-up, tracks, groups).
    /// Zap presses coalesce in ``pendingZap`` and only tune once settled (tick).
    func execute(_ command: PlaybackCommand) {
        switch command {
        case .showInfo:
            visibility.showAutoHiding(.info, timeoutMs: timeouts.infoMs, at: now())
        case .showTransport:
            visibility.showAutoHiding(.infoTransport, timeoutMs: timeouts.infoMs, at: now())
        case .openQuickBar:
            visibility.showAutoHiding(.quickBar, timeoutMs: timeouts.quickBarMs, at: now())
        case let .zap(delta):
            pendingZap.press(delta: delta, at: now())
            showZapInfo()
        case .exitToGuide:
            onExitToGuide()
        case .openPanel, .backToPanel:
            visibility.set(.panel)
        case .dismiss:
            activePicker = nil
            visibility.set(.none)
        case let .popTo(back):
            activePicker = nil
            visibility.set(back)
        case .openMultiview:
            openMultiview()
        case let .moveMultiviewActive(direction):
            moveMultiviewActive(direction)
        case .promoteMultiviewActive:
            promoteMultiviewActive()
        case .exitMultiview:
            exitMultiview()
        case .togglePlayPause:
            togglePlayPause()
        case let .moveTransportFocus(delta):
            transportFocus = transportFocus.moved(by: delta)
        case .activateTransport:
            execute(transportFocus.command)
        case .nothing:
            break
        }
    }
}
