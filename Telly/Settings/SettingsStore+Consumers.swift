import Foundation

/// Bridges the stored scalar settings to the value types their consumers expect:
/// per-overlay auto-hide durations for the live player and millisecond EPG
/// cadence/retention for the refresher, so `AppEnvironment` factories thread
/// pure derived values rather than re-deriving them inline.
extension SettingsStore {
    /// The overlay auto-hide durations for the current panel-timeout setting.
    var panelTimeouts: PanelTimeouts { PanelTimeouts.forSeconds(panelTimeoutSeconds) }

    /// The EPG refresh interval in millis (0 = "Never" → interval refresh off).
    var epgRefreshIntervalMs: Int { RefreshScheduler.hoursToMs(epgRefreshHours) }

    /// The keep-past retention horizon in millis for trimming ended programmes.
    var epgKeepPastMs: Int { RefreshScheduler.daysToMs(epgKeepPastDays) }
}
