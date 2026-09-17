import SwiftUI

/// The stage-switched overlay layers for ``VodPlaybackScreen`` plus its platform
/// input, split out to keep the screen lean (the ``CatchupPlaybackScreen``+`Keys`
/// precedent). Playing renders the auto-hiding ``VodTransportView`` (only while
/// ``VodTransportVisibility/visible``); the resume prompt renders
/// ``VodResumePromptView``; loading shows nothing over the black stage.
extension VodPlaybackScreen {
    @ViewBuilder var layers: some View {
        switch model.stage {
        case .resumePrompt:
            VodResumePromptView(title: model.item?.name ?? "",
                                onResume: { model.resumeStored() },
                                onStartOver: { model.startOver() })
        case .playing:
            if model.visibility.visible {
                VodTransportView(title: model.item?.name ?? "",
                                 progress: model.progress, isPaused: model.isPaused)
            }
        case .loading:
            EmptyView()
        }
    }
}

/// Platform input for VOD playback: tvOS forwards D-pad/play-pause through
/// ``VodPlaybackKeys`` and exits (persist+leave) on MENU/BACK; iPhone/iPad map a
/// tap to pause and a horizontal swipe to a discrete seek onto the same map.
private struct VodPlaybackKeysModifier: ViewModifier {
    let model: VodPlaybackModel

    func body(content: Content) -> some View {
        #if os(tvOS)
        content.focusable()
            .onMoveCommand { dispatch(Self.key(for: $0)) }
            .onPlayPauseCommand { dispatch(.ok) }
            .onExitCommand { model.exit() }
        #else
        content
            .onTapGesture { dispatch(.ok) }
            .gesture(DragGesture(minimumDistance: 20).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dispatch(value.translation.width < 0 ? .left : .right)
            })
        #endif
    }

    private func dispatch(_ key: PlaybackKey) {
        switch VodPlaybackKeys.command(key) {
        case .togglePause: model.togglePause()
        case let .seek(deltaMs): model.seekBy(deltaMs)
        case .revealTransport: model.pokeTransport()
        case .none: break
        }
    }

    #if os(tvOS)
    private static func key(for direction: MoveCommandDirection) -> PlaybackKey {
        switch direction {
        case .left: return .left
        case .right: return .right
        case .up: return .up
        default: return .down
        }
    }
    #endif
}

extension View {
    /// Attach the VOD playback input for `model`.
    func vodPlaybackKeys(_ model: VodPlaybackModel) -> some View {
        modifier(VodPlaybackKeysModifier(model: model))
    }
}
