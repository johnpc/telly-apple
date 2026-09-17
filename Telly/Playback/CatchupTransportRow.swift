import SwiftUI

/// The read-only catch-up transport row on the shared ``BottomOverlayBar`` scrim:
/// a progress bar filled to ``TransportReadout/permille(position:duration:)``, a
/// paused pill while paused, the elapsed/duration spans, and the archive title.
/// Pure presentation — every value is precomputed by ``TransportReadout`` — so it
/// stays coverage-exempt like the other playback `*View`s and previews trivially.
struct CatchupTransportRow: View {
    let title: String?
    let positionMs: Int
    let durationMs: Int
    let isPaused: Bool

    var body: some View {
        BottomOverlayBar {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    if let title, !title.isEmpty { Text(title).font(.headline) }
                    if isPaused { PausedBadgeView() }
                    Spacer()
                    Text("\(TransportReadout.span(positionMs)) / \(TransportReadout.span(durationMs))")
                        .font(.subheadline).monospacedDigit()
                }
                ProgressView(
                    value: Double(TransportReadout.permille(position: positionMs, duration: durationMs)),
                    total: 1000
                ).tint(.white)
            }
        }
    }
}
