import SwiftUI

/// The catch-up chrome pinned top-trailing over the archive player: a
/// "Catch-up · {title} · {range}" pill reusing the reconnecting-pill idiom (an
/// `.ultraThinMaterial` capsule) so it reads as the same system. Top-trailing
/// (not top-leading) keeps it clear of the top-leading Close button on
/// iPhone/iPad; tvOS has no Close button so it stays clean there too. Logic-free —
/// every bit of formatting lives in the pure ``CatchupBadge`` — so it stays
/// coverage-exempt like the other playback `*View`s.
struct CatchupBadgeView: View {
    let badge: CatchupBadge
    let is24h: Bool
    let timeZone: TimeZone

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Catch-up · \(badge.label(is24h: is24h, timeZone: timeZone))")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            Spacer()
        }
        .padding()
    }
}
