import SwiftUI

/// A scrollable strip of genre chips derived from a programme's category field.
/// Renders nothing when there are no categories, so callers can drop it inline
/// without guarding. Shared by the guide info panel and the channel-detail block;
/// the bordered/tinted styling mirrors ``ChannelGroupPickerView``.
struct ProgramInfoChipsView: View {
    let categories: [String]

    var body: some View {
        if !categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                            .font(.caption).fontWeight(.medium)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.secondary.opacity(0.18), in: Capsule())
                    }
                }
            }
        }
    }
}
