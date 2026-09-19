import SwiftUI

/// The programme area of the info overlay: the current title with its air-time
/// window and an elapsed-progress bar, plus the upcoming title — or a
/// "No programme information" placeholder when the EPG has no now/next for the
/// channel. Pure presentation; decisions and formatting live in
/// ``InfoOverlayText`` and ``ProgramProgress``.
struct InfoProgramView: View {
    let nowNext: NowNext?
    let nowMs: Int

    var body: some View {
        if InfoOverlayText.hasProgram(nowNext), let now = nowNext?.now {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Text("\(InfoOverlayText.timeLabel(now.startMs))–\(InfoOverlayText.timeLabel(now.endMs))")
                        .font(.subheadline).monospacedDigit()
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1).fixedSize().layoutPriority(1)
                    Text(now.details.title)
                        .font(.title3).fontWeight(.semibold)
                        .lineLimit(1).truncationMode(.tail)
                }
                if let fraction = ProgramProgress.fraction(
                    nowMs: nowMs, startMs: now.startMs, endMs: now.endMs) {
                    ProgressView(value: fraction).tint(.white).frame(maxWidth: 520)
                }
                if let next = InfoOverlayText.nextTitle(nowNext) {
                    Text("Next: \(next)")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        } else {
            Text("No programme information")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
