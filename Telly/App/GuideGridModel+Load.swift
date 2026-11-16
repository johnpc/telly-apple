import Foundation

/// The guide grid's load lifecycle is the shared ``LoadableModel`` one, with one
/// difference: existing rows do NOT trigger a background refresh (the EPG refresh
/// is a full re-fetch, not a cheap re-read), so the forced refresh runs only for
/// an empty grid and on Retry.
extension GuideGridModel: LoadableModel {
    var hasContent: Bool { !rows.isEmpty }
    var refreshesInBackground: Bool { false }
}
