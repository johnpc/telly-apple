import SwiftUI
import Testing
@testable import Telly

/// The pure compact-width layout decisions: the search preselected card hides on
/// compact and shows on regular/unknown, and the group strip only auto-scrolls
/// to the selection on compact. View geometry is left to the visual capture.
struct CompactLayoutTests {
    @Test func preselectedCardHidesOnCompact() {
        #expect(CompactLayout.showsPreselectedCard(.compact) == false)
    }

    @Test func preselectedCardShowsOnRegular() {
        #expect(CompactLayout.showsPreselectedCard(.regular) == true)
    }

    @Test func preselectedCardShowsWhenSizeClassUnknown() {
        #expect(CompactLayout.showsPreselectedCard(nil) == true)
    }

    @Test func groupStripAutoScrollsOnlyOnCompact() {
        #expect(CompactLayout.autoScrollsGroupStrip(.compact) == true)
    }

    @Test func groupStripDoesNotAutoScrollOnRegular() {
        #expect(CompactLayout.autoScrollsGroupStrip(.regular) == false)
    }

    @Test func groupStripDoesNotAutoScrollWhenSizeClassUnknown() {
        #expect(CompactLayout.autoScrollsGroupStrip(nil) == false)
    }

    @Test func posterColumnMinimumIsSmallerOnCompact() {
        #expect(CompactLayout.posterColumnMinimum(.compact) == 100)
    }

    @Test func posterColumnMinimumIsPosterScaleOnRegular() {
        #expect(CompactLayout.posterColumnMinimum(.regular) == 168)
    }

    @Test func posterColumnMinimumIsPosterScaleWhenSizeClassUnknown() {
        #expect(CompactLayout.posterColumnMinimum(nil) == 168)
    }
}
