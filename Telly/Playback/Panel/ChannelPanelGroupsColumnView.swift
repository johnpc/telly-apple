import SwiftUI

/// The panel's group selector with the selected group highlighted: a vertical
/// column beside the rows on tvOS / regular width, or a leading-aligned
/// horizontal scroll strip on a compact iPhone (where a fixed side column would
/// starve the rows). Pure presentation; the selected index comes from the
/// parent's ``PanelSelection``.
struct ChannelPanelGroupsColumnView: View {
    let groups: [String]
    let selectedIndex: Int
    var horizontal = false

    var body: some View {
        content
        #if !os(tvOS)
            // The top-leading groups sit under the shared circular ``PlaybackCloseButton``
            // (only present off tvOS); inset the leading edge so the ✕ never overlaps the
            // first group label, in both the compact strip and the regular side column.
            .padding(.leading, 44)
        #endif
    }

    @ViewBuilder private var content: some View {
        if horizontal {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(groups.enumerated()), id: \.offset) { index, name in
                        chip(name, selected: index == selectedIndex)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, name in
                    chip(name, selected: index == selectedIndex)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
            }
            .frame(width: 220)
        }
    }

    private func chip(_ name: String, selected: Bool) -> some View {
        Text(name)
            .font(.headline)
            .foregroundStyle(selected ? .white : .white.opacity(0.55))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .tellyFocus(selected)
    }
}
