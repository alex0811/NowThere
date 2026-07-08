import XCTest
@testable import NowThereCore

final class TimeZoneStoreTests: XCTestCase {
    func testLoadTimeZoneUsesFallbackWhenNoValueIsSaved() throws {
        let defaults = makeDefaults()
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { tokyo })

        let loaded = store.loadTimeZone()

        XCTAssertEqual(loaded.identifier, "Asia/Tokyo")
    }

    func testLoadTimeZoneRewritesInvalidSavedIdentifierToFallback() throws {
        let defaults = makeDefaults()
        defaults.set("Mars/Olympus", forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier)
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { utc })

        let loaded = store.loadTimeZone()

        XCTAssertEqual(loaded.identifier, utc.identifier)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier), utc.identifier)
    }

    func testSaveTimeZonePersistsIdentifier() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let newYork = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        store.saveTimeZone(newYork)

        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier), "America/New_York")
    }

    func testLoadVisibilityDefaultsEveryFieldToVisible() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        let visibility = store.loadVisibility()

        XCTAssertEqual(visibility, .allVisible)
    }

    func testSaveVisibilityPersistsFieldSwitches() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let saved = FieldVisibility(
            showsCity: false,
            showsDate: true,
            showsWeekday: false,
            showsTime: true
        )

        store.saveVisibility(saved)
        let loaded = store.loadVisibility()

        XCTAssertEqual(loaded, saved)
    }

    func testLoadCustomLabelDefaultsToEmptyString() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        XCTAssertEqual(store.loadCustomLabel(), "")
    }

    func testSaveCustomLabelPersistsValue() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        store.saveCustomLabel("Work")

        XCTAssertEqual(store.loadCustomLabel(), "Work")
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.customLabel), "Work")
    }

    func testLoadTitleStyleDefaultsToStandard() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        XCTAssertEqual(store.loadTitleStyle(), .standard)
    }

    func testSaveTitleStylePersistsValue() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        store.saveTitleStyle(.separated)

        XCTAssertEqual(store.loadTitleStyle(), .separated)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.titleStyle), "separated")
    }

    func testLoadTitleStyleRewritesInvalidSavedValueToStandard() {
        let defaults = makeDefaults()
        defaults.set("outline", forKey: TimeZoneStoreKeys.titleStyle)
        let store = TimeZoneStore(defaults: defaults)

        let loaded = store.loadTitleStyle()

        XCTAssertEqual(loaded, .standard)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.titleStyle), TitleStyle.standard.rawValue)
    }

    func testLoadTimeFormatDefaultsToTwentyFourHour() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        XCTAssertEqual(store.loadTimeFormat(), .twentyFourHour)
    }

    func testSaveTimeFormatPersistsValue() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        store.saveTimeFormat(.twelveHour)

        XCTAssertEqual(store.loadTimeFormat(), .twelveHour)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.timeFormat), "twelveHour")
    }

    func testLoadTimeFormatRewritesInvalidSavedValueToTwentyFourHour() {
        let defaults = makeDefaults()
        defaults.set("system", forKey: TimeZoneStoreKeys.timeFormat)
        let store = TimeZoneStore(defaults: defaults)

        let loaded = store.loadTimeFormat()

        XCTAssertEqual(loaded, .twentyFourHour)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.timeFormat), TimeFormat.twentyFourHour.rawValue)
    }

    func testLoadInterfaceLanguageDefaultsToSystem() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        XCTAssertEqual(store.loadInterfaceLanguage(), .system)
    }

    func testSaveInterfaceLanguagePersistsValue() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        store.saveInterfaceLanguage(.simplifiedChinese)

        XCTAssertEqual(store.loadInterfaceLanguage(), .simplifiedChinese)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.interfaceLanguage), "simplifiedChinese")
    }

    func testLoadInterfaceLanguageRewritesInvalidSavedValueToSystem() {
        let defaults = makeDefaults()
        defaults.set("klingon", forKey: TimeZoneStoreKeys.interfaceLanguage)
        let store = TimeZoneStore(defaults: defaults)

        let loaded = store.loadInterfaceLanguage()

        XCTAssertEqual(loaded, .system)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.interfaceLanguage), InterfaceLanguage.system.rawValue)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowThereTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
