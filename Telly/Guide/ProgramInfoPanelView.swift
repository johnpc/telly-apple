import SwiftUI

/// The program info panel body: the channel identity, the programme's timing
/// badge + air-time range, title / subtitle / episode, genre chips, the full
/// synopsis (or a clean empty state), and the per-cell action buttons. Pure
/// presentation — every string comes from ``ProgramInfoPresentation`` and the
/// action set from ``GuideCellActions``.
struct ProgramInfoPanelView: View {
    let target: GuideInfoTarget
    let model: GuideGridModel
    let onPlay: (GuideSelection) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if os(tvOS)
        scroller
        #else
        NavigationStack {
            scroller
                .navigationTitle("Programme")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        #endif
    }

    @ViewBuilder private var scroller: some View {
        if let program = target.cell.program {
            let info = ProgramInfoPresentation.make(
                program: program, nowMs: model.now(), timeZone: model.timeZone)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ProgramInfoHeaderView(channel: target.channel)
                    ProgramInfoHeadlineView(info: info)
                    ProgramInfoChipsView(categories: info.categories)
                    synopsis(info)
                    ProgramInfoActionsView(target: target, model: model, onPlay: onPlay)
                }
                .padding(Self.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private func synopsis(_ info: ProgramInfoPresentation) -> some View {
        if let description = info.description {
            Text(description).font(.body).foregroundStyle(.primary)
        } else {
            ContentUnavailableView("No description available", systemImage: "text.alignleft")
                .frame(maxWidth: .infinity)
        }
    }

    #if os(tvOS)
    private static let padding: CGFloat = 48
    #else
    private static let padding: CGFloat = 20
    #endif
}
