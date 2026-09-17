import SwiftUI

/// The fullscreen track picker pushed over the quick-bar: a titled card of
/// full-width selectable rows (audio / captions / audio-sync) over a dimming
/// scrim. Rows are focusable Buttons so the tvOS D-pad drives selection while
/// the screen's `onExitCommand` still delivers BACK; on a compact iPhone the
/// rows stay full-width and vertical so nothing clips horizontally. Presentation
/// only — the rows and what a tap does come from ``LivePlaybackModel``'s pure
/// track slice.
struct TrackPickerView: View {
    let title: String
    let rows: [TrackPickerRow]
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title2.bold())
            if rows.isEmpty {
                Text("No tracks available").foregroundStyle(.secondary)
            } else {
                ForEach(rows, id: \.id) { row in
                    Button { onSelect(row.id) } label: { TrackPickerRowView(row: row) }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: 460, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.85)))
        .foregroundStyle(.white)
    }
}
