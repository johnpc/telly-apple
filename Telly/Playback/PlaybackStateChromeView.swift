import SwiftUI

/// Shared player state-chrome, factored out of ``PlaybackScreen`` and
/// ``LivePlaybackScreen`` so the buffering spinner / reconnecting pill / error
/// text and the iOS Close button live in exactly one place. Callers decide
/// *when* to show the overlay (e.g. ``LivePlaybackScreen`` suppresses it during
/// a zap hold); this view only decides *how* each ``PlayerState`` looks.
struct PlaybackStateOverlay: View {
    let state: PlayerState

    var body: some View {
        switch state {
        case .buffering:
            ProgressView().controlSize(.large).tint(.white)
        case .reconnecting:
            Text("Reconnecting…")
                .font(.headline).foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        case let .error(message):
            Text(message).font(.headline).foregroundStyle(.white)
                .multilineTextAlignment(.center).padding()
        default:
            EmptyView()
        }
    }
}

#if !os(tvOS)
/// Top-leading dismiss affordance for the touch platforms; tvOS uses the Menu
/// button instead so this is compiled out there.
struct PlaybackCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title).foregroundStyle(.white)
                }
                .padding()
                Spacer()
            }
            Spacer()
        }
    }
}
#endif
