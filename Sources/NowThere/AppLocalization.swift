import Foundation

enum AppLocalizationKey: String, CaseIterable {
    case detailsTimeZone = "details.timeZone"
    case detailsDate = "details.date"
    case detailsWeekday = "details.weekday"
    case detailsTime = "details.time"
    case detailsUTCOffset = "details.utcOffset"
    case searchTitle = "search.title"
    case searchPlaceholder = "search.placeholder"
    case searchEmpty = "search.empty"
    case settingsMenuBarFields = "settings.menuBarFields"
    case settingsCustomLabel = "settings.customLabel"
    case settingsCustomLabelPlaceholder = "settings.customLabel.placeholder"
    case settingsTitleStyle = "settings.titleStyle"
    case settingsTitleStyleStandard = "settings.titleStyle.standard"
    case settingsTitleStyleTimeFirst = "settings.titleStyle.timeFirst"
    case settingsTitleStyleSeparated = "settings.titleStyle.separated"
    case settingsTitleStyleBracketed = "settings.titleStyle.bracketed"
    case settingsTimeFormat = "settings.timeFormat"
    case settingsTimeFormatTwentyFourHour = "settings.timeFormat.twentyFourHour"
    case settingsTimeFormatTwelveHour = "settings.timeFormat.twelveHour"
    case settingsFieldCityLabel = "settings.field.cityLabel"
    case settingsFieldDate = "settings.field.date"
    case settingsFieldWeekday = "settings.field.weekday"
    case settingsFieldTime = "settings.field.time"
    case settingsLaunchAtLogin = "settings.launchAtLogin"
    case launchAtLoginErrorUpdateFailed = "launchAtLogin.error.updateFailed"
    case commandQuit = "command.quit"
}

enum AppLocalization {
    static let supportedLocalizations = ["en", "zh-Hans", "ja"]

    static func string(_ key: AppLocalizationKey) -> String {
        Bundle.module.localizedString(
            forKey: key.rawValue,
            value: nil,
            table: "Localizable"
        )
    }

    static func string(_ key: AppLocalizationKey, localization: String) -> String {
        strings(for: localization)[key.rawValue] ?? key.rawValue
    }

    static func strings(for localization: String) -> [String: String] {
        guard let url = Bundle.module.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: localization
        ) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
            return plist as? [String: String] ?? [:]
        } catch {
            return [:]
        }
    }
}
