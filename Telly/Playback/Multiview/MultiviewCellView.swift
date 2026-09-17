import SwiftUI

/// One multiview tile. A deterministic colour-from-id plus the channel name is
/// the base layer — also the loading / fake-surface content when no engine is
/// attached. When the tile is backed by the real VLCKit engine a
/// `VideoSurfaceView` is layered over it; the active tile draws a highlight ring.
/// On iPad a tap activates the tile.
struct MultiviewCellView: View {
    let cell: MultiviewCell
    let engine: (any PlayerEngine)?
    let isActive: Bool
    let onActivate: () -> Void

    var body: some View {
        ZStack {
            tileColor
            Text(cell.channel.displayName)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(8)
            if let vlc = engine as? VLCKitPlayerEngine {
                VideoSurfaceView(engine: vlc)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.accentColor, lineWidth: isActive ? 5 : 0)
        }
        #if !os(tvOS)
        .contentShape(Rectangle())
        .onTapGesture(perform: onActivate)
        #endif
    }

    private var tileColor: Color {
        Color(hue: Double(cell.id % 8) / 8.0, saturation: 0.55, brightness: 0.45)
    }
}
