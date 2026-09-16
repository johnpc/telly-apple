import Testing
@testable import Telly

/// The persisted resize-mode string mapped onto the surface resize enum.
struct ResizeModeTests {
    @Test func fillSynonyms() {
        #expect(ResizeMode.from("stretch") == .fill)
        #expect(ResizeMode.from("fill") == .fill)
    }

    @Test func zoomSynonyms() {
        #expect(ResizeMode.from("crop") == .zoom)
        #expect(ResizeMode.from("zoom") == .zoom)
    }

    @Test func fixedModes() {
        #expect(ResizeMode.from("fixed width") == .fixedWidth)
        #expect(ResizeMode.from("fixed height") == .fixedHeight)
    }

    @Test func trimmingAndCasingAreNormalized() {
        #expect(ResizeMode.from("  FILL  ") == .fill)
        #expect(ResizeMode.from("Fixed Width") == .fixedWidth)
    }

    @Test func unknownAndFitFallBackToFit() {
        #expect(ResizeMode.from("fit") == .fit)
        #expect(ResizeMode.from("nonsense") == .fit)
        #expect(ResizeMode.from("") == .fit)
    }
}
