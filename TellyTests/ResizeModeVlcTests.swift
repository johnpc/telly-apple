import Testing
@testable import Telly

/// The pure ``ResizeMode`` → ``VlcVideoLayout`` mapping and the cycling helper —
/// the aspect-string / crop / stretch directives the real engine hands VLCKit.
struct ResizeModeVlcTests {
    @Test func fitClearsEverything() {
        #expect(ResizeMode.fit.vlcLayout == VlcVideoLayout())
    }

    @Test func ratioModesForceDisplayAspect() {
        #expect(ResizeMode.ratio16x9.vlcLayout == VlcVideoLayout(aspectRatio: "16:9"))
        #expect(ResizeMode.ratio4x3.vlcLayout == VlcVideoLayout(aspectRatio: "4:3"))
    }

    @Test func zoomCropsToWidescreen() {
        #expect(ResizeMode.zoom.vlcLayout == VlcVideoLayout(cropGeometry: "16:9"))
    }

    @Test func fillStretchesToSurface() {
        #expect(ResizeMode.fill.vlcLayout == VlcVideoLayout(stretchToFill: true))
    }

    @Test func legacyFixedModesFallBackToFit() {
        #expect(ResizeMode.fixedWidth.vlcLayout == VlcVideoLayout())
        #expect(ResizeMode.fixedHeight.vlcLayout == VlcVideoLayout())
    }

    @Test func nextCyclesThroughSelectableAndWraps() {
        #expect(ResizeMode.fit.next() == .fill)
        #expect(ResizeMode.fill.next() == .ratio16x9)
        #expect(ResizeMode.zoom.next() == .fit)          // wraps at the end
    }

    @Test func nextFromANonSelectableModeStartsAtFit() {
        #expect(ResizeMode.fixedWidth.next() == .fit)
    }
}
