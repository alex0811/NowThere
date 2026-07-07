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

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowThereTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
