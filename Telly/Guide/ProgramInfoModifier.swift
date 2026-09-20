import SwiftUI

/// Presents the guide's program info panel for `target` as a sheet (a focusable
/// card on tvOS, a detented sheet on iPhone/iPad) — the Apple take on TiviMate's
/// programme popup. The panel shows the synopsis plus the per-cell action; Watch
/// and catch-up route back through `onPlay` (the shared tune path) and dismiss,
/// while the My List toggle stays put so its label flips in place.
struct ProgramInfoModifier: ViewModifier {
    @Binding var target: GuideInfoTarget?
    let model: GuideGridModel
    let onPlay: (GuideSelection) -> Void

    func body(content: Content) -> some View {
        content.sheet(item: $target) { target in
            ProgramInfoPanelView(target: target, model: model,
                                 onPlay: { onPlay($0); self.target = nil })
        }
    }
}

extension View {
    /// Presents the program info panel for `target` (see ``ProgramInfoModifier``).
    func guideProgramInfo(_ target: Binding<GuideInfoTarget?>, model: GuideGridModel,
                          onPlay: @escaping (GuideSelection) -> Void) -> some View {
        modifier(ProgramInfoModifier(target: target, model: model, onPlay: onPlay))
    }
}
