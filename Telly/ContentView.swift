import SwiftUI

/// Root shell. This is the onboarding-empty state until the playlist/guide
/// slices land: "Telly doesn't provide any channels — add a playlist." Ported
/// 1:1 from the Android welcome screen (telly `features/onboarding`).
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Telly")
                .font(.largeTitle.bold())
            Text("Add a playlist from your IPTV provider to start watching.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
