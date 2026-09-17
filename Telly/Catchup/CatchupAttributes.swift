import Foundation

/// A channel's usable catch-up capability, resolved from its raw columns.
/// Ported 1:1 from Android `CatchupAttributes` (CatchupAttributes.kt:30-53).
struct CatchupAttributes: Equatable {
    let type: CatchupType
    let source: String?
    let days: Int

    /// Horizon when `catchup-days` is absent (matches the EPG past-days default).
    static let defaultDays = 7
}

extension ChannelEntity {
    /// Nil when the channel cannot play catch-up: no recognised type (a bare
    /// `catchup-source` implies `.default`), or a template type without its
    /// `catchup-source` template. Days fall back to `defaultDays` (7).
    func catchupAttributes() -> CatchupAttributes? {
        let source = catchup.catchupSource.flatMap {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0
        }
        let type = CatchupType.of(catchup.catchupType) ?? (source != nil ? .default : nil)
        guard let type, source != nil || type.rewritesLiveUrl else { return nil }
        return CatchupAttributes(type: type,
                                 source: source,
                                 days: catchup.catchupDays ?? CatchupAttributes.defaultDays)
    }
}
