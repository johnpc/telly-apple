import SwiftUI

/// The track-picker overlay layer for ``LivePlaybackScreen``: renders the pushed
/// picker card when a picker is active, wiring the model's pure rows / title and
/// row selection back through. Kept in its own `*View.swift` file so the screen's
/// ZStack just composes it, matching the other overlay ViewBuilders.
extension LivePlaybackScreen {
    @ViewBuilder var trackPickerOverlay: some View {
        if case .pushed = model.overlay, model.activePicker != nil {
            TrackPickerView(title: model.pickerTitle, rows: model.pickerRows,
                            onSelect: { model.selectPickerRow($0) })
                .overlayTransition(reduceMotion: reduceMotion)
        }
    }
}
