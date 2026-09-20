import SwiftUI

/// The per-pane menu over the multiview grid: Change channel / Fullscreen /
/// Remove pane / Add pane, with the highlighted row ringed via ``tellyFocus``.
/// Rows are pure buttons so a tap (iOS/iPad) activates directly; the D-pad
/// highlight (tvOS) is driven by the model through the screen key forwarder. All
/// row composition lives in ``MultiviewMenu`` — this is presentation only.
struct MultiviewPaneMenuView: View {
    let rows: [MultiviewMenuRow]
    let selection: Int
    let onSelect: (MultiviewMenuRow) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    Button { onSelect(row) } label: { label(row) }
                        .buttonStyle(.plain)
                        .tellyFocus(index == selection)
                }
            }
            .padding(20)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func label(_ row: MultiviewMenuRow) -> some View {
        HStack(spacing: 14) {
            Image(systemName: row.symbol).frame(width: 28)
            Text(row.title).font(.headline)
            Spacer(minLength: 40)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .frame(minWidth: 280)
    }
}
