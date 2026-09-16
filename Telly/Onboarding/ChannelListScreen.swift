import SwiftUI

/// The post-onboarding channel list: number, name and group per visible
/// channel, with an Add button to run the wizard again. Selecting a row opens
/// the live player fullscreen on that channel's stream. A placeholder for the
/// full guide/panel slices — enough to verify onboarding lands on playback.
struct ChannelListScreen: View {
    let channelStore: ChannelStore
    let makeEngine: () -> VLCKitPlayerEngine
    let onAdd: () -> Void
    @State private var channels: [ChannelEntity] = []
    @State private var target: PlaybackTarget?

    var body: some View {
        NavigationStack {
            List(channels, id: \.id) { channel in
                Button {
                    target = PlaybackTarget(id: channel.id, url: channel.source.streamUrl)
                } label: {
                    ChannelRow(channel: channel)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Channels")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", action: onAdd)
                }
            }
        }
        .task { channels = (try? channelStore.visibleChannels()) ?? [] }
        .fullScreenCover(item: $target) { target in
            PlaybackScreen(streamUrl: target.url, engine: makeEngine())
        }
    }
}

/// Identifies the channel currently being played (drives the fullscreen cover).
private struct PlaybackTarget: Identifiable {
    let id: Int
    let url: String
}

/// One channel row: sequential number, display name and optional group.
private struct ChannelRow: View {
    let channel: ChannelEntity

    var body: some View {
        HStack(spacing: 12) {
            Text("\(channel.number)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.displayName)
                if let group = channel.source.groupTitle, !group.isEmpty {
                    Text(group).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
