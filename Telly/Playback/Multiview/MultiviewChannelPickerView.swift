import SwiftUI

/// The channel picker opened from the pane menu (Change channel / Add pane): the
/// full channel list, one tappable row each, with the highlighted row ringed via
/// ``tellyFocus``. Reuses the same number + name row shape as the in-playback
/// channel panel; selecting a row loads that channel into the pane (or a new one)
/// through the model. Presentation only — the load routing lives in the model.
struct MultiviewChannelPickerView: View {
    let channels: [ChannelEntity]
    let selection: Int
    let title: String
    let onSelect: (ChannelEntity) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(Array(channels.enumerated()), id: \.offset) { index, channel in
                            Button { onSelect(channel) } label: { row(channel) }
                                .buttonStyle(.plain)
                                .tellyFocus(index == selection)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 520)
        }
    }

    private func row(_ channel: ChannelEntity) -> some View {
        HStack(spacing: 16) {
            Text("\(channel.number)")
                .font(.title3).monospacedDigit().fontWeight(.semibold)
                .frame(width: 52, alignment: .trailing)
            Text(channel.displayName).font(.headline)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}
