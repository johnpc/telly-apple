import Foundation

/// The VLCMediaPlayer display directive a ``ResizeMode`` resolves to: a forced
/// display aspect ratio (`videoAspectRatio`, a C-string like "16:9"), a crop
/// geometry (`videoCropGeometry`), and a stretch flag the engine turns into the
/// drawable's own ratio so the picture fills the surface. `nil`/`false` leave the
/// source aspect untouched — VLC's default "Fit" letterbox. Pure and testable;
/// the real engine (`VLCKitPlayerEngine+Resize`) applies it to `char *` props.
struct VlcVideoLayout: Equatable {
    var aspectRatio: String?
    var cropGeometry: String?
    var stretchToFill = false
}

extension ResizeMode {
    /// The VLC geometry this mode forces. Fit clears everything; the ratio modes
    /// force a display aspect; Zoom crops to 16:9 to fill; Fill stretches to the
    /// surface. The legacy ExoPlayer `fixed*` modes (store-string only) fall back
    /// to Fit, having no VLC analogue.
    var vlcLayout: VlcVideoLayout {
        switch self {
        case .fit, .fixedWidth, .fixedHeight: return VlcVideoLayout()
        case .fill: return VlcVideoLayout(stretchToFill: true)
        case .zoom: return VlcVideoLayout(cropGeometry: "16:9")
        case .ratio16x9: return VlcVideoLayout(aspectRatio: "16:9")
        case .ratio4x3: return VlcVideoLayout(aspectRatio: "4:3")
        }
    }
}
