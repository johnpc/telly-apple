import Foundation

/// Track-selection seam of the playback engine (quick-bar pickers, catalogue
/// stream slots): logic talks to this protocol only, so tests inject a fake and
/// never touch the VLC track APIs. Deliberately not class-bound — a value-type
/// adapter may conform. Ported from the Android `TrackFacade` interface.
protocol TrackFacade {
    var snapshot: TrackSnapshot { get }

    /// Audio-sync offset, positive = audio delayed. Per-session, not persisted.
    var audioOffsetMs: Int { get }

    /// Applies a video override; nil returns to adaptive "Auto".
    func selectVideo(_ id: String?)

    func selectAudio(_ id: String)

    /// Enables the given text track; nil turns captions off.
    func selectText(_ id: String?)

    func setAudioOffsetMs(_ ms: Int)
}
