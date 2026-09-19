import SwiftUI

/// Identifies the guide cell whose programme action menu is open: the channel it
/// belongs to (for the My List key) and the info-carrying cell being acted on.
struct GuideCellMenuTarget: Identifiable {
    let channel: ChannelEntity
    let cell: GuideCell
    var id: String { "\(channel.id)|\(cell.startMs)" }
}

/// The guide cell's programme action menu — the Apple mirror of Android's
/// `GuideScreenCellMenu` (capture 27), pared to the one action telly ships:
/// Add to / Remove from My List (Remind/Record are tabled). OK/tap on an
/// info-carrying, non-airing cell presents it; the row label flips on saved
/// state exactly like Android's `MyListKeys.label`. Focusable + dismissable on
/// every platform (a confirmation dialog is the tvOS-safe menu primitive).
struct GuideCellMenuView: ViewModifier {
    @Binding var target: GuideCellMenuTarget?
    let model: GuideGridModel

    func body(content: Content) -> some View {
        content.confirmationDialog(target?.cell.program?.details.title ?? "",
                                   isPresented: presented, titleVisibility: .visible,
                                   presenting: target) { target in
            Button(MyListToggle.label(saved: model.isSaved(channel: target.channel, cell: target.cell))) {
                model.toggleMyList(channel: target.channel, cell: target.cell)
            }
        }
    }

    /// Bridges the item-style `target` to the dialog's `isPresented`, clearing it on dismiss.
    private var presented: Binding<Bool> {
        Binding(get: { target != nil }, set: { if !$0 { target = nil } })
    }
}

extension View {
    /// Presents the guide cell's My List menu for `target` (see ``GuideCellMenuView``).
    func guideCellMenu(_ target: Binding<GuideCellMenuTarget?>, model: GuideGridModel) -> some View {
        modifier(GuideCellMenuView(target: target, model: model))
    }
}
