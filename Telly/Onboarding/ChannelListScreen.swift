import SwiftUI

/// The post-onboarding channel list: number, name and group per visible
/// channel, with an Add button to run the wizard again. A placeholder for the
/// full guide/panel slices — enough to verify onboarding lands somewhere real.
struct ChannelListScreen: View {
    let channelStore: ChannelStore
    let onAdd: () -> Void
    @State private var channels: [ChannelEntity] = []

    var body: some View {
        NavigationStack {
            List(channels, id: \.id) { channel in
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
            .navigationTitle("Channels")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", action: onAdd)
                }
            }
        }
        .task { channels = (try? channelStore.visibleChannels()) ?? [] }
    }
}
