#if DEBUG
import Foundation

/// DEBUG-only launch flag for the load-state screenshots: `-tellyLoadState
/// <loading|empty|error>` pins the channel list into one `LoadPhase` so the
/// skeleton, the empty message and the error+Retry state can be captured
/// deterministically — no real playlist, never touching the provider.
extension DebugLaunch {
    enum LoadStateDemo: String {
        case loading, empty, error

        var phase: LoadPhase {
            switch self {
            case .loading: return .loading
            case .empty: return .empty
            case .error: return .failed
            }
        }
    }

    static func loadStateDemo(in args: [String]) -> LoadStateDemo? {
        value(for: "-tellyLoadState", in: args).flatMap(LoadStateDemo.init(rawValue:))
    }
}
#endif
