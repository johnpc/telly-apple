import SwiftUI

/// The "Guide Data" settings group: how often the EPG refreshes ("Never" when
/// disabled) and how many days of ended programmes to keep before trimming.
struct SettingsGuideSectionView: View {
    @Bindable var settings: SettingsStore

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
        }
    }
}
