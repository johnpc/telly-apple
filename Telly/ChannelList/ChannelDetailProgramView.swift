import SwiftUI

/// The channel detail pane's now/next block. Renders the current programme's
/// title, air-time window, elapsed progress, genre chips and a truncated synopsis,
/// plus the upcoming title — or a placeholder when the EPG has no now/next. Uses
/// system foreground styles (the pane sits on the app background, not over dimmed
/// video), reusing the shared ``ProgramInfoPresentation`` / ``ProgramProgress``
/// helpers rather than re-inlining any formatting.
struct ChannelDetailProgramView: View {
    let nowNext: NowNext?
    let nowMs: Int
    var timeZone: TimeZone = .current

    var body: some View {
        if let now = nowNext?.now {
            let info = ProgramInfoPresentation.make(program: now, nowMs: nowMs, timeZone: timeZone)
            VStack(alignment: .leading, spacing: 10) {
                Text("Now Playing").font(.caption).textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(info.title).font(.title2).fontWeight(.semibold)
                Text(info.timeRange).font(.subheadline).monospacedDigit()
                    .foregroundStyle(.secondary)
                if let fraction = ProgramProgress.fraction(
                    nowMs: nowMs, startMs: now.startMs, endMs: now.endMs) {
                    ProgressView(value: fraction).frame(maxWidth: 420)
                }
                ProgramInfoChipsView(categories: info.categories).frame(maxWidth: 420)
                if let description = info.description {
                    Text(description).font(.callout).foregroundStyle(.secondary)
                        .lineLimit(3).frame(maxWidth: 420, alignment: .leading)
                }
                if let next = InfoOverlayText.nextTitle(nowNext) {
                    Text("Next: \(next)").font(.callout).foregroundStyle(.secondary)
                }
            }
        } else {
            Text("No programme information").font(.callout).foregroundStyle(.secondary)
        }
    }
}
