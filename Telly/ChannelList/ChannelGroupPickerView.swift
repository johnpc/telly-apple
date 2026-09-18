import SwiftUI

/// The channel-list group filter: a horizontal, scrollable strip of group
/// buttons (scrollable so it never clips on the narrow iPhone), the selected
/// one emphasised. Focusable on tvOS, tap-selectable on iPhone/iPad.
struct ChannelGroupPickerView: View {
    let groups: [String]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(groups, id: \.self) { group in
                    Button(group) { TellyHaptics.selection(); onSelect(group) }
                        .buttonStyle(.bordered)
                        .tint(group == selected ? .accentColor : .secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
