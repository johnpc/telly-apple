import Foundation

/// Transport clock texts: `m:ss` under an hour, `h:mm:ss` at/above an hour.
/// Pure integer math ported 1:1 from the Android `VodTimes`; negative inputs
/// clamp to zero so a mid-load sample never renders a minus sign.
enum VodTimes {
    static func format(ms: Int) -> String {
        let total = max(0, ms / 1000)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }
}
