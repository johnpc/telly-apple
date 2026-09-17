import Foundation

/// The persisted scalar-preference keys. Sensitive credentials (e.g. a parental
/// PIN) are deliberately absent — those belong in the Keychain as a salted hash,
/// never in plaintext `UserDefaults`.
enum SettingsKey: String, CaseIterable {
    case use24hClock
    case panelTimeoutSeconds
    case epgRefreshHours
    case epgKeepPastDays
    case playerKeyOk
    case playerKeyUpDown
    case playerKeyLeftRight
    case playerKeyLongOk
    case parentalEnabled
}

/// Factory-fresh values used until the user changes a setting, plus the choice
/// lists the picker surfaces offer.
enum SettingsDefaults {
    static let use24hClock = true
    static let panelTimeoutSeconds = 5
    static let epgRefreshHours = 24
    static let epgKeepPastDays = 7
    static let panelTimeoutChoices = [3, 5, 10, 30]
    static let refreshHourChoices = [0, 6, 12, 24, 48]
    static let keepPastDayChoices = [1, 3, 7, 14, 30]
    static let playerKeyOk = PlayerOkAction.showInfo.rawValue
    static let playerKeyUpDown = PlayerUpDownAction.showInfo.rawValue
    static let playerKeyLeftRight = PlayerLeftRightAction.nothing.rawValue
    static let playerKeyLongOk = PlayerLongOkAction.quickMenu.rawValue
    static let parentalEnabled = false
}
