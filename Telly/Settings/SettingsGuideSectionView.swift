import SwiftUI

/// The "Guide Data" settings group: how often the EPG refreshes ("Never" when
/// disabled), how many days of ended programmes to keep, an app-wide "refresh
/// EPG when a playlist changes" toggle, and a manual "Update EPG now" action.
struct SettingsGuideSectionView: View {
    @Bindable var settings: SettingsStore
    /// The forced EPG refresh reached by "Update EPG now" (injected by the host).
    let updateEpgNow: () async -> UpdateOutcome
    /// The per-channel EPG-assignment entry list (vended off the cap-safe carrier).
    let makeEpgAssignmentModel: () -> EpgAssignmentModel

    var body: some View {
        Section("Guide Data") {
            Picker("Refresh Every", selection: $settings.epgRefreshHours) {
                ForEach(SettingsDefaults.refreshHourChoices, id: \.self) { hours in
                    Text(hours == 0 ? "Never" : "\(hours) h").tag(hours)
                }
            }
            Picker("Keep Past", selection: $settings.epgKeepPastDays) {
                ForEach(SettingsDefaults.keepPastDayChoices, id: \.self) { days in
                    Text("\(days) d").tag(days)
                }
            }
            Toggle("Update on Playlists Change", isOn: $settings.updateOnPlaylistsChange)
            UpdateActionButton(title: "Update EPG Now") { await updateEpgNow() }
            NavigationLink("EPG Assignment") {
                EpgAssignmentScreen(model: makeEpgAssignmentModel())
            }
        }
    }
}
