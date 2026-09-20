import Foundation
import UIKit
import VLCKitSPM

/// Video resize / aspect-ratio control for the real engine, split from the
/// primary adapter to keep it within the source-line budget (the `+Audio` /
/// `+Transport` precedent). Translates the pure ``VlcVideoLayout`` onto VLCKit's
/// `char *` display properties: `strdup` hands libVLC an owned copy (it copies
/// internally), `nil` resets to the source aspect. Stretch forces the drawable's
/// own ratio so the picture fills the surface. Untestable device glue by nature.
extension VLCKitPlayerEngine {
    func setResizeMode(_ mode: ResizeMode) {
        let layout = mode.vlcLayout
        let aspect = layout.stretchToFill ? drawableAspect() : layout.aspectRatio
        player.videoAspectRatio = aspect.flatMap { strdup($0) }
        player.videoCropGeometry = layout.cropGeometry.flatMap { strdup($0) }
        player.scaleFactor = 0
    }

    /// The drawable's own `W:H` so VLC stretches the picture to fill it (Fill);
    /// nil until the surface has non-zero bounds.
    private func drawableAspect() -> String? {
        guard let bounds = drawable?.bounds, bounds.width > 0, bounds.height > 0 else { return nil }
        return "\(Int(bounds.width)):\(Int(bounds.height))"
    }
}
