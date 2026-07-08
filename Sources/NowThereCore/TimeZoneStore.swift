import Foundation

enum TimeZoneStoreKeys {
    static let selectedTimeZoneIdentifier = "selectedTimeZoneIdentifier"
    static let customLabel = "customLabel"
    static let showsCity = "fieldVisibility.showsCity"
    static let showsDate = "fieldVisibility.showsDate"
    static let showsWeekday = "fieldVisibility.showsWeekday"
    static let showsTime = "fieldVisibility.showsTime"
}

public final class TimeZoneStore {
    private let defaults: UserDefaults
    private let fallbackTimeZone: () -> TimeZone

    public init(
        defaults: UserDefaults = .standard,
        fallbackTimeZone: @escaping () -> TimeZone = { .current }
    ) {
        self.defaults = defaults
        self.fallbackTimeZone = fallbackTimeZone
    }

    public func loadTimeZone() -> TimeZone {
        guard let savedIdentifier = defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier) else {
            return fallbackTimeZone()
        }

        guard let savedTimeZone = TimeZone(identifier: savedIdentifier) else {
            let fallback = fallbackTimeZone()
            saveTimeZone(fallback)
            return fallback
        }

        return savedTimeZone
    }

    public func saveTimeZone(_ timeZone: TimeZone) {
        defaults.set(timeZone.identifier, forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier)
    }

    public func loadCustomLabel() -> String {
        defaults.string(forKey: TimeZoneStoreKeys.customLabel) ?? ""
    }

    public func saveCustomLabel(_ label: String) {
        defaults.set(label, forKey: TimeZoneStoreKeys.customLabel)
    }

    public func loadVisibility() -> FieldVisibility {
        FieldVisibility(
            showsCity: bool(forKey: TimeZoneStoreKeys.showsCity, defaultValue: true),
            showsDate: bool(forKey: TimeZoneStoreKeys.showsDate, defaultValue: true),
            showsWeekday: bool(forKey: TimeZoneStoreKeys.showsWeekday, defaultValue: true),
            showsTime: bool(forKey: TimeZoneStoreKeys.showsTime, defaultValue: true)
        )
    }

    public func saveVisibility(_ visibility: FieldVisibility) {
        defaults.set(visibility.showsCity, forKey: TimeZoneStoreKeys.showsCity)
        defaults.set(visibility.showsDate, forKey: TimeZoneStoreKeys.showsDate)
        defaults.set(visibility.showsWeekday, forKey: TimeZoneStoreKeys.showsWeekday)
        defaults.set(visibility.showsTime, forKey: TimeZoneStoreKeys.showsTime)
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
}
