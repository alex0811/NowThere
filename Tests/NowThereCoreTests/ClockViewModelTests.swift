import XCTest
@testable import NowThereCore

@MainActor
final class ClockViewModelTests: XCTestCase {
    func testInitialStateUsesStoredPreferencesAndBuildsTitle() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveVisibility(FieldVisibility(
            showsCity: true,
            showsDate: false,
            showsWeekday: false,
            showsTime: true
        ))
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)

        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: true),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(viewModel.selectedTimeZone.identifier, "Asia/Tokyo")
        XCTAssertEqual(viewModel.visibility, FieldVisibility(
            showsCity: true,
            showsDate: false,
            showsWeekday: false,
            showsTime: true
        ))
        XCTAssertEqual(viewModel.menuTitle, "Tokyo 12:34")
        XCTAssertTrue(viewModel.isLaunchAtLoginEnabled)
    }

    func testSelectingTimeZonePersistsAndRefreshesTitle() throws {
        let defaults = makeDefaults()
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { utc })
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        viewModel.selectTimeZone(identifier: "Asia/Tokyo")

        XCTAssertEqual(viewModel.selectedTimeZone.identifier, "Asia/Tokyo")
        XCTAssertEqual(viewModel.menuTitle, "Tokyo Jul 08 Wed 12:34")
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier), "Asia/Tokyo")
    }

    func testInvalidTimeZoneSelectionDoesNotChangeState() throws {
        let defaults = makeDefaults()
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { utc })
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        viewModel.selectTimeZone(identifier: "Mars/Olympus")

        XCTAssertEqual(viewModel.selectedTimeZone.identifier, utc.identifier)
    }

    func testFieldTogglePersistsAndFallsBackToAppNameWhenAllFieldsAreHidden() throws {
        let defaults = makeDefaults()
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { utc })
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        viewModel.setField(.city, isVisible: false)
        viewModel.setField(.date, isVisible: false)
        viewModel.setField(.weekday, isVisible: false)
        viewModel.setField(.time, isVisible: false)

        XCTAssertEqual(viewModel.menuTitle, "NowThere")
        XCTAssertEqual(store.loadVisibility(), FieldVisibility(
            showsCity: false,
            showsDate: false,
            showsWeekday: false,
            showsTime: false
        ))
    }

    func testLaunchAtLoginFailureRollsBackToActualStateAndShowsMessage() {
        let store = TimeZoneStore(defaults: makeDefaults())
        let loginManager = FakeLoginItemManager(isEnabled: false)
        loginManager.errorToThrow = FakeLoginItemError.failed
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: loginManager,
            nowProvider: { Date(timeIntervalSince1970: 0) },
            startsTimer: false
        )

        viewModel.setLaunchAtLogin(true)

        XCTAssertFalse(viewModel.isLaunchAtLoginEnabled)
        XCTAssertEqual(viewModel.launchAtLoginErrorMessage, "Could not update launch setting")
    }

    func testSearchResultsAreForwardedFromSearchService() {
        let store = TimeZoneStore(defaults: makeDefaults())
        let search = TimeZoneSearch(identifiers: ["Asia/Tokyo", "Europe/London"])
        let viewModel = ClockViewModel(
            store: store,
            search: search,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { Date(timeIntervalSince1970: 0) },
            startsTimer: false
        )

        let results = viewModel.searchResults(matching: "Tokyo")

        XCTAssertEqual(results.map(\.identifier), ["Asia/Tokyo"])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowThereTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static func utcDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return try XCTUnwrap(calendar.date(from: components))
    }
}

private final class FakeLoginItemManager: LoginItemManaging {
    var isEnabled: Bool
    var errorToThrow: Error?

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if let errorToThrow {
            throw errorToThrow
        }
        isEnabled = enabled
    }
}

private enum FakeLoginItemError: Error {
    case failed
}
