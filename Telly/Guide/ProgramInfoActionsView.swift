import SwiftUI

/// The program info panel's action buttons, one per ``GuideCellActions`` entry
/// for the cell's activation outcome: Watch (airing) / catch-up (past-eligible)
/// route through `onPlay`; My List toggles in place, its label flipping on saved
/// state. Existing behaviour is preserved — the panel only adds the synopsis
/// above these actions.
struct ProgramInfoActionsView: View {
    let target: GuideInfoTarget
    let model: GuideGridModel
    let onPlay: (GuideSelection) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(GuideCellActions.actions(for: target.selection), id: \.self) { action in
                if let title = action.playTitle {
                    play(label: title, systemImage: action.playIcon)
                } else {
                    myListButton
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func play(label: String, systemImage: String) -> some View {
        Button { TellyHaptics.selection(); onPlay(target.selection) } label: {
            Label(label, systemImage: systemImage).frame(maxWidth: 360)
        }
        .buttonStyle(.borderedProminent).controlSize(.large)
    }

    private var myListButton: some View {
        Button {
            TellyHaptics.selection()
            model.toggleMyList(channel: target.channel, cell: target.cell)
        } label: {
            Label(MyListToggle.label(saved: saved), systemImage: bookmark).frame(maxWidth: 360)
        }
        .buttonStyle(.bordered).controlSize(.large)
    }

    private var saved: Bool { model.isSaved(channel: target.channel, cell: target.cell) }
    private var bookmark: String { saved ? "bookmark.fill" : "bookmark" }
}
