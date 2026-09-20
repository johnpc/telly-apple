import SwiftUI

/// The aspect-ratio picker overlay layer for ``LivePlaybackScreen``: renders the
/// pushed picker card when the resize picker is active, reusing the shared
/// ``TrackPickerView`` and wiring the model's pure rows / selection back through.
/// Kept in its own `*View.swift` file so the screen's ZStack just composes it,
/// matching the track-picker overlay.
extension LivePlaybackScreen {
    @ViewBuilder var resizePickerOverlay: some View {
        if case .pushed = model.overlay, model.resizePickerActive {
            TrackPickerView(title: ResizeModeChoices.title, rows: model.resizePickerRows,
                            onSelect: { model.selectResizeRow($0) })
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }
}
