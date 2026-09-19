import SwiftUI

/// The channel-list group filter: a horizontal, scrollable strip of group
/// buttons (scrollable so it never clips on the narrow iPhone), the selected
/// one emphasised. Focusable on tvOS, tap-selectable on iPhone/iPad. On compact
/// width it auto-scrolls to reveal the selected/deep-linked group, which can sit
/// off-screen; iPad frames the full strip and tvOS scrolls it via focus.
struct ChannelGroupPickerView: View {
    let groups: [String]
    let selected: String
    let onSelect: (String) -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
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
            .onAppear { revealSelected(proxy) }
            .onChange(of: selected) { _, _ in revealSelected(proxy) }
        }
    }

    private func revealSelected(_ proxy: ScrollViewProxy) {
        guard CompactLayout.autoScrollsGroupStrip(sizeClass) else { return }
        withAnimation(Motion.gated(Motion.route, reduceMotion: reduceMotion)) {
            proxy.scrollTo(selected, anchor: .center)
        }
    }
}
