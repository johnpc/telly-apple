import Testing
@testable import Telly

/// The `playlistId → url` index: saved rows map their `Int` id to their URL and
/// unsaved rows (nil id) are skipped.
struct PlaylistUrlIndexTests {
    @Test func mapsSavedRowsAndSkipsUnsaved() {
        let playlists = [
            PlaylistEntity(id: 1, name: "A", url: "http://h/a.m3u"),
            PlaylistEntity(id: 2, name: "B", url: "http://h/b.m3u"),
            PlaylistEntity(id: nil, name: "C", url: "http://h/c.m3u")]
        let index = PlaylistUrlIndex.build(playlists)
        #expect(index == [1: "http://h/a.m3u", 2: "http://h/b.m3u"])
    }

    @Test func emptyForNoPlaylists() {
        #expect(PlaylistUrlIndex.build([]).isEmpty)
    }
}
