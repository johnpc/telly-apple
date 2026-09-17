import SwiftUI

/// The panel's channel-rows column: a vertical ScrollView of now-playing rows —
/// number, name, the current title with its air-time range, an elapsed-progress
/// bar, and the next title — with the focused row highlighted. A compact layout
/// distinct from the info overlay's programme block. Pure presentation.
struct ChannelPanelRowsColumnView: View {
    let rows: [PanelRowInfo]
    let focusedIndex: Int

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    rowView(row, focused: index == focusedIndex)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rowView(_ row: PanelRowInfo, focused: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(row.displayNumber)")
                .font(.title3).monospacedDigit().fontWeight(.semibold)
                .frame(width: 52, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                Text(row.name).font(.headline)
                programme(row)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(focused ? Color.white.opacity(0.18) : .clear)
    }

    @ViewBuilder private func programme(_ row: PanelRowInfo) -> some View {
        if let title = row.nowTitle {
            HStack(spacing: 10) {
                if let range = row.nowRange {
                    Text(range).font(.caption).monospacedDigit()
                        .foregroundStyle(.white.opacity(0.6))
                }
                Text(title).font(.subheadline)
            }
            if let progress = row.progress {
                ProgressView(value: progress).tint(.white).frame(maxWidth: 360)
            }
            if let next = row.nextTitle {
                Text("Up next: \(next)").font(.caption).foregroundStyle(.white.opacity(0.6))
            }
        } else {
            Text("No programme guide").font(.caption).foregroundStyle(.white.opacity(0.5))
        }
    }
}
