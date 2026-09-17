import SwiftUI

/// The VOD seek transport on the shared ``BottomOverlayBar`` scrim (Apple mirror
/// of Android's `VodTransport`): the movie title, a paused pill, the
/// elapsed/duration clocks formatted by ``VodTimes``, and a progress track filled
/// to the ``VodProgress/permille`` with a draggable-looking thumb. Pure
/// presentation — every value is precomputed by the model — so it stays
/// coverage-exempt like the other playback `*View`s.
struct VodTransportView: View {
    let title: String
    let progress: VodProgress
    let isPaused: Bool

    var body: some View {
        BottomOverlayBar {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    if !title.isEmpty { Text(title).font(.headline) }
                    if isPaused { PausedBadgeView() }
                    Spacer()
                    Text("\(VodTimes.format(ms: progress.positionMs)) / \(VodTimes.format(ms: progress.durationMs))")
                        .font(.subheadline).monospacedDigit()
                }
                track
            }
        }
    }

    private var track: some View {
        GeometryReader { geo in
            let fraction = Double(progress.permille) / 1000
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25)).frame(height: 4)
                Capsule().fill(.white).frame(width: geo.size.width * fraction, height: 4)
                Circle().fill(.white).frame(width: 14, height: 14)
                    .offset(x: geo.size.width * fraction - 7)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 16)
    }
}
