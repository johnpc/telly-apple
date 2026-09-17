import SwiftUI

/// The typed-query results: a Channels shelf (reusing ``ChannelListRowView``,
/// captioned with the now-playing title) above the Programs master-lane — one
/// section per matched channel, its channel card followed by each matching
/// airing as a row of title + time (and remaining, when live). Tapping a
/// channel hit or a Programs channel tunes it; the preselected airing drives the
/// detail card. Pure presentation over ``SearchModel``.
struct SearchResultsView: View {
    let model: SearchModel

    var body: some View {
        List {
            if !model.results.channels.isEmpty {
                Section("Channels") {
                    ForEach(model.results.channels, id: \.channel.id) { hit in channelRow(hit) }
                }
            }
            ForEach(model.results.programs, id: \.channel.id) { channel in programSection(channel) }
        }
        .overlay(alignment: .bottom) { detailCard }
    }

    @ViewBuilder private func channelRow(_ hit: SearchChannelHit) -> some View {
        Button { model.onChannelResult(hit) } label: {
            VStack(alignment: .leading, spacing: 2) {
                ChannelListRowView(channel: hit.channel)
                if let nowTitle = hit.nowTitle {
                    Text(nowTitle).font(.caption).foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func programSection(_ channel: SearchProgramChannel) -> some View {
        Section(channel.channel.displayName) {
            Button { model.onProgramChannelResult(channel) } label: {
                ChannelListRowView(channel: channel.channel)
            }
            .buttonStyle(.plain)
            ForEach(channel.airings, id: \.program.id) { hit in airingRow(hit) }
        }
    }

    @ViewBuilder private func airingRow(_ hit: SearchProgramHit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hit.title)
            Text(hit.timeText + (hit.remaining.map { " · \($0)" } ?? ""))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var detailCard: some View {
        if let program = model.focusedProgram { SearchDetailCardView(program: program) }
    }
}
