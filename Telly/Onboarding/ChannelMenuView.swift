import SwiftUI

/// The per-channel "Channel options" menu — the Apple mirror of the channel
/// section of Android's `PlayerMenu`, consolidating the built per-channel actions
/// (favourite toggle, Hide, Assign EPG) behind the row's long-press. Rendering
/// only; the row set + labels come from the pure ``ChannelMenuActions`` and every
/// mutation delegates to ``ChannelListModel`` (no parallel favourite/hide path).
/// Applied to the stack row and the iPad split sidebar row so neither carries a
/// copy. A `View`-suffixed file → excluded from unit coverage (acceptance-tested).
extension View {
    /// Attaches the consolidated channel menu as the row's long-press context
    /// menu. Favourite/Hide mutate `model`; Assign EPG raises the sheet target.
    func channelMenu(_ channel: ChannelEntity, model: ChannelListModel,
                     assignTarget: Binding<AssignEpgTarget?>) -> some View {
        contextMenu { channelMenuButtons(channel, model: model, assignTarget: assignTarget) }
    }

    /// Presents the per-channel Assign-EPG picker for `item` (raised by the menu),
    /// reloading the list on dismiss so a new override reflects on the row.
    func assignEpgSheet(_ item: Binding<AssignEpgTarget?>,
                        make: @escaping (ChannelEntity) -> AssignEpgModel,
                        onReload: @escaping () -> Void) -> some View {
        sheet(item: item, onDismiss: onReload) { target in
            NavigationStack { AssignEpgScreen(model: make(target.channel)) }
        }
    }
}

/// The menu's buttons, shared by the production context menu and the DEBUG
/// confirmation-dialog proof so both render the identical rows in Android's order.
@ViewBuilder func channelMenuButtons(_ channel: ChannelEntity, model: ChannelListModel,
                                     assignTarget: Binding<AssignEpgTarget?>) -> some View {
    ForEach(ChannelMenuActions.actions(for: channel), id: \.self) { action in
        let title = ChannelMenuActions.label(action, for: channel)
        switch action {
        case .toggleFavorite: Button(title) { model.toggleFavorite(channel) }
        case .hide: Button(title, role: .destructive) { model.hide(channel) }
        case .assignEpg: Button(title) { assignTarget.wrappedValue = AssignEpgTarget(channel: channel) }
        }
    }
}

#if DEBUG
extension View {
    /// DEBUG screenshot proof: renders the identical menu rows in a confirmation
    /// dialog (titled with the channel name) that ``ChannelMenuScreenshotSeed``
    /// auto-opens, so a plain `simctl` still captures the consolidated menu — the
    /// context menu itself cannot be expanded headlessly. Mirrors the guide
    /// cell-menu proof idiom; never present in release builds.
    func channelMenuProof(_ target: Binding<ChannelEntity?>, model: ChannelListModel,
                          assignTarget: Binding<AssignEpgTarget?>) -> some View {
        confirmationDialog(target.wrappedValue?.displayName ?? "",
                           isPresented: Binding(get: { target.wrappedValue != nil },
                                                set: { if !$0 { target.wrappedValue = nil } }),
                           titleVisibility: .visible, presenting: target.wrappedValue) { channel in
            channelMenuButtons(channel, model: model, assignTarget: assignTarget)
        }
    }
}
#endif
