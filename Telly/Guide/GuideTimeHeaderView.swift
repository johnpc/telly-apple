import SwiftUI

/// The guide's scrolling 30-min time header: each `GuideTick` from
/// `GuideTimeline.ticks` rendered as a clock label pinned at its on-screen
/// `offset`. Pure rendering; the tick offsets and labels are computed upstream.
struct GuideTimeHeaderView: View {
    let ticks: [GuideTick]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(ticks, id: \.offset) { tick in
                Text(tick.label)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .offset(x: tick.offset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
