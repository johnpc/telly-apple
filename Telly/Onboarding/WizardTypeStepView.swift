import SwiftUI

/// The source-type chooser. M3U and Xtream Codes are wired; the Stalker row
/// renders disabled with a "Soon" tag, matching the Android chooser.
struct WizardTypeStepView: View {
    let model: AddPlaylistModel

    var body: some View {
        List {
            Section("Choose a source") {
                ForEach(PlaylistType.allCases, id: \.self) { type in
                    Button { model.chooseType(type) } label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            if type.isAvailable {
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            } else {
                                Text("Soon").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(!type.isAvailable)
                }
            }
        }
    }
}
