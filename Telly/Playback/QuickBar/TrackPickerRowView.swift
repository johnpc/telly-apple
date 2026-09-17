import SwiftUI

/// One picker row: its label with a leading checkmark when it is the active
/// option, laid out full-width so the whole row is a comfortable focus / tap
/// target on both the remote and a narrow phone.
struct TrackPickerRowView: View {
    let row: TrackPickerRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .frame(width: 22)
                .opacity(row.checked ? 1 : 0)
            Text(row.label)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 10)
    }
}
