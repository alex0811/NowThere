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
        store.saveCustomLabel("Work")
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
        XCTAssertEqual(viewModel.customLabel, "Work")
        XCTAssertEqual(viewModel.menuTitle, "Work Tokyo 12:34")
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

    func testSettingCustomLabelPersistsAndRefreshesTitle() throws {
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

        viewModel.setCustomLabel("Work")

        XCTAssertEqual(viewModel.customLabel, "Work")
        XCTAssertEqual(viewModel.menuTitle, "Work UTC Jul 08 Wed 03:34")
        XCTAssertEqual(store.loadCustomLabel(), "Work")
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

    func testCustomLabelIsShownWhenAllFieldsAreHidden() throws {
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

        viewModel.setCustomLabel("Work")
        viewModel.setField(.city, isVisible: false)
        viewModel.setField(.date, isVisible: false)
        viewModel.setField(.weekday, isVisible: false)
        viewModel.setField(.time, isVisible: false)

        XCTAssertEqual(viewModel.menuTitle, "Work")
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

    func testTimerStartsAtNextMinuteBoundaryThenRepeatsEverySixtySeconds() throws {
        let store = TimeZoneStore(defaults: makeDefaults(), fallbackTimeZone: {
            TimeZone(secondsFromGMT: 0)!
        })
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveVisibility(FieldVisibility(
            showsCity: false,
            showsDate: false,
            showsWeekday: false,
            showsTime: true
        ))

        let firstDate = try Self.utcDate(
            year: 2026,
            month: 7,
            day: 8,
            hour: 3,
            minute: 34,
            second: 45
        )
        let secondDate = try Self.utcDate(
            year: 2026,
            month: 7,
            day: 8,
            hour: 3,
            minute: 35,
            second: 0
        )

        var dates = [firstDate, secondDate]
        let scheduler = FakeClockTimerScheduler()
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { dates.removeFirst() },
            timerScheduler: scheduler,
            startsTimer: true
        )

        XCTAssertEqual(viewModel.menuTitle, "12:34")
        XCTAssertEqual(scheduler.scheduledTimers.count, 1)
        XCTAssertEqual(scheduler.scheduledTimers[0].interval, 15, accuracy: 0.0001)
        XCTAssertFalse(scheduler.scheduledTimers[0].repeats)

        scheduler.fireLastScheduledTimer()

        XCTAssertEqual(viewModel.menuTitle, "12:35")
        XCTAssertEqual(scheduler.scheduledTimers.count, 2)
        XCTAssertEqual(scheduler.scheduledTimers[1].interval, 60, accuracy: 0.0001)
        XCTAssertTrue(scheduler.scheduledTimers[1].repeats)
    }

    func testTimerSchedulerInvalidatesUnderlyingTimerWhenViewModelIsReleased() throws {
        let store = TimeZoneStore(defaults: makeDefaults(), fallbackTimeZone: {
            TimeZone(secondsFromGMT: 0)!
        })
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        store.saveTimeZone(utc)
        let probe = InvalidationProbe()
        weak var weakViewModel: ClockViewModel?

        do {
            let scheduler = FakeClockTimerScheduler(invalidationProbe: probe)
            var viewModel: ClockViewModel? = ClockViewModel(
                store: store,
                loginItemManager: FakeLoginItemManager(isEnabled: false),
                nowProvider: { Date(timeIntervalSince1970: 0) },
                timerScheduler: scheduler,
                startsTimer: true
            )
            weakViewModel = viewModel
            XCTAssertNotNil(weakViewModel)
            viewModel = nil
        }

        XCTAssertNil(weakViewModel)
        XCTAssertEqual(probe.invalidateCount, 1)
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
        minute: Int,
        second: Int = 0
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
            minute: minute,
            second: second
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

private final class FakeClockTimerScheduler: ClockTimerScheduling {
    struct ScheduledTimer {
        let interval: TimeInterval
        let repeats: Bool
        let action: () -> Void
    }

    private final class TrackingTimer {
        private var isInvalidated = false
        private let invalidationProbe: InvalidationProbe

        init(invalidationProbe: InvalidationProbe) {
            self.invalidationProbe = invalidationProbe
        }

        func invalidate() {
            guard !isInvalidated else {
                return
            }

            isInvalidated = true
            invalidationProbe.invalidateCount += 1
        }
    }

    private(set) var scheduledTimers: [ScheduledTimer] = []
    private var timer: TrackingTimer?
    private let invalidationProbe: InvalidationProbe?

    init(invalidationProbe: InvalidationProbe? = nil) {
        self.invalidationProbe = invalidationProbe
    }

    func schedule(after interval: TimeInterval, repeats: Bool, action: @escaping () -> Void) {
        timer?.invalidate()
        timer = TrackingTimer(invalidationProbe: invalidationProbe ?? InvalidationProbe())
        scheduledTimers.append(ScheduledTimer(interval: interval, repeats: repeats, action: action))
    }

    func fireLastScheduledTimer() {
        scheduledTimers.last?.action()
    }

    deinit {
        timer?.invalidate()
    }
}

private final class InvalidationProbe {
    var invalidateCount = 0
}
