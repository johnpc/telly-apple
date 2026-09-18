import SwiftUI

/// The interactive transport row of the expanded info overlay (`.infoTransport`):
/// previous-channel, play/pause and next-channel controls, laid across the shared
/// info scrim below the now/next bar. Live is never scrubbable (the `isLive`
/// seam), so its transport is play/pause + channel change; the now/next progress
/// bar above is the live-position indicator. Focus is model-driven
/// (``LiveTransportButton`` via ``tellyFocus(_:cornerRadius:)``) so the tvOS
/// remote's LEFT/RIGHT/OK and an iPhone tap drive the identical actions — no
/// parallel native-focus engine. Pure presentation, coverage-exempt like the
/// other playback `*View`s.
struct LiveTransportRow: View {
    let focus: LiveTransportButton
    let isPaused: Bool
    var onTap: (LiveTransportButton) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 28) {
            ForEach(LiveTransportButton.allCases, id: \.self) { control($0) }
        }
    }

    @ViewBuilder private func control(_ button: LiveTransportButton) -> some View {
        #if os(tvOS)
        slot(button)
        #else
        Button { onTap(button) } label: { slot(button) }.buttonStyle(.plain)
        #endif
    }

    private func slot(_ button: LiveTransportButton) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol(button)).font(.title2)
                .frame(width: 60, height: 60)
                .background(Circle().fill(.white.opacity(0.15)))
            Text(label(button)).font(.caption)
        }
        .tellyFocus(button == focus, cornerRadius: 30)
    }

    private func symbol(_ button: LiveTransportButton) -> String {
        switch button {
        case .channelDown: return "backward.end.fill"
        case .playPause: return isPaused ? "play.fill" : "pause.fill"
        case .channelUp: return "forward.end.fill"
        }
    }

    private func label(_ button: LiveTransportButton) -> String {
        switch button {
        case .channelDown: return "Channel down"
        case .playPause: return isPaused ? "Play" : "Pause"
        case .channelUp: return "Channel up"
        }
    }
}
