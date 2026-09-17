import Foundation

/// The outcome of activating (OK / tap) one guide cell. CORE ships single-stage
/// (DECISION 3): a cell airing now tunes straight to fullscreen playback, a cell
/// carrying future/other programme info opens its detail, and a "No information"
/// filler is inert. The two-stage preview→fullscreen flow and the cell dropdown
/// are deferred. `ChannelEntity` and `GuideCell` are `Equatable`, so the
/// conformance is synthesised — every case is asserted in the tests.
enum GuideSelection: Equatable {
    /// Play this channel's catch-up archive for the past programme in the cell.
    case catchup(ChannelEntity, GuideCell)
    /// Tune to this channel's live stream (the cell is airing now).
    case tune(ChannelEntity)
    /// Show programme detail for a non-airing cell that carries info.
    case info(GuideCell)
    /// Nothing to do (a filler cell with no programme).
    case none
}
