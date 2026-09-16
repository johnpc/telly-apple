import Foundation

/// The inert ``TrackFacade`` the live engine exposes until real track
/// enumeration lands: an empty snapshot and no-op selections. Lets
/// `VLCKitPlayerEngine` satisfy the protocol without pulling the VLC track APIs
/// into this slice.
final class NoTracks: TrackFacade {
    let snapshot = TrackSnapshot()
    let audioOffsetMs = 0

    func selectVideo(_ id: String?) {}
    func selectAudio(_ id: String) {}
    func selectText(_ id: String?) {}
    func setAudioOffsetMs(_ ms: Int) {}
}
