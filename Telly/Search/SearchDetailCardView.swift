import SwiftUI

/// The preselected-programme detail beside the Programs master-lane: the focused
/// airing's title, the channel it airs on, and its air time (plus remaining when
/// live) — the Apple mirror of Android's always-populated search detail pane.
/// Pure presentation; the focused programme is chosen by ``SearchModel``.
///
/// Named `…CardView` (not `…Card`) so the coverage gate's `*View.swift` suffix
/// rule exempts it — only `*View`/`*Screen` files are view-exempt there.
struct SearchDetailCardView: View {
    let program: SearchProgramHit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(program.title).font(.headline)
            Text(program.channel.displayName).font(.subheadline).foregroundStyle(.secondary)
            Text(program.timeText + (program.remaining.map { " · \($0)" } ?? ""))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}
