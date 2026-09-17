import SwiftUI

/// The guide's "now" indicator: a thin vertical rule at the on-screen offset from
/// `GuideTimeline.nowLineOffset`, drawing nothing when the current instant is off
/// the visible pane. Stretches to the enclosing stack's height. Pure rendering.
struct GuideNowLineView: View {
    let offset: CGFloat?

    var body: some View {
        if let offset {
            Rectangle()
                .fill(.red)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .offset(x: offset)
        }
    }
}
