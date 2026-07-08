import Foundation
import NowThereCore

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
    case settingsLanguage = "settings.language"
    case settingsLanguageSystem = "settings.language.system"
    case settingsLanguageEnglish = "settings.language.english"
    case settingsLanguageSimplifiedChinese = "settings.language.simplifiedChinese"
    case settingsLanguageJapanese = "settings.language.japanese"
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

    static func string(_ key: AppLocalizationKey, language: InterfaceLanguage) -> String {
        guard let localization = localizationIdentifier(for: language) else {
            return string(key)
        }

        return string(key, localization: localization)
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

    private static func localizationIdentifier(for language: InterfaceLanguage) -> String? {
        switch language {
        case .system:
            nil
        case .english:
            "en"
        case .simplifiedChinese:
            "zh-Hans"
        case .japanese:
            "ja"
        }
    }
}

enum AppMenuLabels {
    static func interfaceLanguageName(_ interfaceLanguage: InterfaceLanguage) -> String {
        AppLocalization.string(localizationKey(for: interfaceLanguage))
    }

    static func interfaceLanguageName(
        _ interfaceLanguage: InterfaceLanguage,
        localization: String
    ) -> String {
        AppLocalization.string(localizationKey(for: interfaceLanguage), localization: localization)
    }

    static func interfaceLanguageName(
        _ interfaceLanguage: InterfaceLanguage,
        language: InterfaceLanguage
    ) -> String {
        AppLocalization.string(localizationKey(for: interfaceLanguage), language: language)
    }

    static func titleStyleName(_ titleStyle: TitleStyle) -> String {
        AppLocalization.string(localizationKey(for: titleStyle))
    }

    static func titleStyleName(_ titleStyle: TitleStyle, localization: String) -> String {
        AppLocalization.string(localizationKey(for: titleStyle), localization: localization)
    }

    static func titleStyleName(_ titleStyle: TitleStyle, language: InterfaceLanguage) -> String {
        AppLocalization.string(localizationKey(for: titleStyle), language: language)
    }

    static func timeFormatName(_ timeFormat: TimeFormat) -> String {
        AppLocalization.string(localizationKey(for: timeFormat))
    }

    static func timeFormatName(_ timeFormat: TimeFormat, localization: String) -> String {
        AppLocalization.string(localizationKey(for: timeFormat), localization: localization)
    }

    static func timeFormatName(_ timeFormat: TimeFormat, language: InterfaceLanguage) -> String {
        AppLocalization.string(localizationKey(for: timeFormat), language: language)
    }

    static func clockFieldName(_ field: ClockField) -> String {
        AppLocalization.string(localizationKey(for: field))
    }

    static func clockFieldName(_ field: ClockField, localization: String) -> String {
        AppLocalization.string(localizationKey(for: field), localization: localization)
    }

    static func clockFieldName(_ field: ClockField, language: InterfaceLanguage) -> String {
        AppLocalization.string(localizationKey(for: field), language: language)
    }

    static func launchAtLoginErrorMessage(_ error: LaunchAtLoginError) -> String {
        AppLocalization.string(localizationKey(for: error))
    }

    static func launchAtLoginErrorMessage(
        _ error: LaunchAtLoginError,
        localization: String
    ) -> String {
        AppLocalization.string(localizationKey(for: error), localization: localization)
    }

    static func launchAtLoginErrorMessage(
        _ error: LaunchAtLoginError,
        language: InterfaceLanguage
    ) -> String {
        AppLocalization.string(localizationKey(for: error), language: language)
    }

    private static func localizationKey(for interfaceLanguage: InterfaceLanguage) -> AppLocalizationKey {
        switch interfaceLanguage {
        case .system:
            .settingsLanguageSystem
        case .english:
            .settingsLanguageEnglish
        case .simplifiedChinese:
            .settingsLanguageSimplifiedChinese
        case .japanese:
            .settingsLanguageJapanese
        }
    }

    private static func localizationKey(for titleStyle: TitleStyle) -> AppLocalizationKey {
        switch titleStyle {
        case .standard:
            .settingsTitleStyleStandard
        case .timeFirst:
            .settingsTitleStyleTimeFirst
        case .separated:
            .settingsTitleStyleSeparated
        case .bracketed:
            .settingsTitleStyleBracketed
        }
    }

    private static func localizationKey(for timeFormat: TimeFormat) -> AppLocalizationKey {
        switch timeFormat {
        case .twentyFourHour:
            .settingsTimeFormatTwentyFourHour
        case .twelveHour:
            .settingsTimeFormatTwelveHour
        }
    }

    private static func localizationKey(for field: ClockField) -> AppLocalizationKey {
        switch field {
        case .city:
            .settingsFieldCityLabel
        case .date:
            .settingsFieldDate
        case .weekday:
            .settingsFieldWeekday
        case .time:
            .settingsFieldTime
        }
    }

    private static func localizationKey(for error: LaunchAtLoginError) -> AppLocalizationKey {
        switch error {
        case .updateFailed:
            .launchAtLoginErrorUpdateFailed
        }
    }
}
