import Testing
@testable import Telly

/// The refresh-stable resume identity is `streamUrl|name` (deliberately NOT
/// `ChannelImporter.keyOf`, matching Android). `isVod` is covered by
/// `PlaylistSummaryTests`.
struct VodClassifierTests {
    @Test func itemKeyJoinsStreamUrlAndName() {
        #expect(VodClassifier.itemKey(streamUrl: "http://x/m.mp4", name: "Movie") == "http://x/m.mp4|Movie")
        #expect(VodClassifier.itemKey(streamUrl: "", name: "") == "|")
    }
}
