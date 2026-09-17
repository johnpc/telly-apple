import SwiftUI

/// The "Paused" pill shown in the transport overlays (live catch-up and VOD)
/// while playback is paused. Shared so the two transport rows don't duplicate it.
struct PausedBadgeView: View {
    var body: some View {
        Text("Paused").font(.caption).bold()
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
