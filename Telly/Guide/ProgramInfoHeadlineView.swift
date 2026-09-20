import SwiftUI

/// The program info panel's headline block: the timing badge ("Now"/"Next") and
/// air-time range on one line, then the title and any subtitle / episode marker.
/// Pure presentation over ``ProgramInfoPresentation``.
struct ProgramInfoHeadlineView: View {
    let info: ProgramInfoPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                if let badge = info.timing.label {
                    Text(badge).font(.caption).fontWeight(.bold).textCase(.uppercase)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.tint, in: Capsule()).foregroundStyle(.white)
                }
                Text(info.timeRange).font(.subheadline).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(info.title).font(.title2).fontWeight(.bold)
            if let subtitle = info.subtitle {
                Text(subtitle).font(.headline).foregroundStyle(.secondary)
            }
            if let episode = info.episode {
                Text(episode).font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
        }
    }
}
