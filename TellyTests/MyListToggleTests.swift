import Testing
@testable import Telly

/// Pure `MyListToggle` logic: identity-key format, membership test, Add↔Remove
/// label flip, and programme→`MyListEntry` snapshot mapping.
struct MyListToggleTests {
    @Test func keyJoinsChannelKeyAndStart() {
        #expect(MyListToggle.key(channelKey: "abc", startMs: 42) == "abc|42")
    }

    @Test func isSavedTestsMembership() {
        let keys: Set<String> = [MyListToggle.key(channelKey: "a", startMs: 100)]
        #expect(MyListToggle.isSaved(keys: keys, channelKey: "a", startMs: 100))
        #expect(!MyListToggle.isSaved(keys: keys, channelKey: "a", startMs: 200))
    }

    @Test func labelFlipsOnSavedState() {
        #expect(MyListToggle.label(saved: true) == "Remove from My List")
        #expect(MyListToggle.label(saved: false) == "Add to My List")
    }

    @Test func entrySnapshotsProgrammeFields() {
        let e = MyListToggle.entry(channelKey: "a", title: "Show", description: "D",
                                   startMs: 100, endMs: 200, addedAtMs: 500)
        #expect(e == MyListEntry(channelKey: "a", startMs: 100, endMs: 200,
                                 title: "Show", description: "D", addedAtMs: 500))
    }
}
