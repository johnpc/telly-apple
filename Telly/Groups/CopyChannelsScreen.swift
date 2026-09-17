import SwiftUI

/// Copy-channels pane — the Apple port of Android's `CopyChannelsSession`. When
/// there are no custom groups it shows a "Create a custom group first" prompt;
/// with more than one it shows a target picker (skipped for a single group); then
/// a channel checklist (HIDDEN channels already excluded) and a Done action that
/// copies the checked channels into the target group. Pure presentation — every
/// mutation delegates to ``CopyChannelsModel``.
struct CopyChannelsScreen: View {
    @State private var model: CopyChannelsModel
    @Environment(\.dismiss) private var dismiss

    init(model: CopyChannelsModel) { _model = State(initialValue: model) }

    var body: some View {
        Form {
            if model.groups.isEmpty {
                Text("Create a custom group first").foregroundStyle(.secondary)
            } else {
                if model.groups.count > 1 { targetSection }
                channelSection
                Section {
                    Button("Done") { model.commit() }.disabled(model.target == nil)
                }
            }
        }
        .navigationTitle("Copy Channels")
        .task {
            model.load()
            model.onDone = { dismiss() }
        }
    }

    private var targetSection: some View {
        Section("Target Group") {
            ForEach(model.groups) { group in
                Button { model.pickTarget(group) } label: {
                    HStack {
                        Text(group.name)
                        Spacer(minLength: 0)
                        if model.target?.id == group.id { Image(systemName: "checkmark") }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var channelSection: some View {
        Section("Channels") {
            ForEach(model.channels, id: \.id) { channel in
                Button { model.toggle(channel) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: model.selection.contains(channel.id)
                              ? "checkmark.circle.fill" : "circle")
                        ChannelEditRowView(channel: channel)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
