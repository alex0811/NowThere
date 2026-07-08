import AppKit
import XCTest
@testable import NowThere
@testable import NowThereCore

@MainActor
final class MenuBarTitleTests: XCTestCase {
    func testMenuBarLabelUsesVisibleClockTitleText() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)

        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(NowThereMenuBarLabel.title(for: viewModel), "Tokyo Jul 08 Wed 12:34")
    }

    func testMenuBarLabelIncludesCustomLabelFromViewModel() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveCustomLabel("Work")

        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(NowThereMenuBarLabel.title(for: viewModel), "Work Tokyo Jul 08 Wed 12:34")
    }

    func testMenuBarLabelConfiguresNativeStatusButtonAppearance() {
        let display = FakeMenuBarTitleDisplay()

        NowThereMenuBarLabel.configure(display, title: "Tokyo Jul 08 Wed 12:34")

        let expectedFont = NSFont.menuBarFont(ofSize: 0)
        XCTAssertEqual(display.title, "Tokyo Jul 08 Wed 12:34")
        XCTAssertEqual(display.font?.fontName, expectedFont.fontName)
        XCTAssertEqual(display.font?.pointSize, expectedFont.pointSize)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowThereAppTests.\(UUID().uuidString)"
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

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        isEnabled = enabled
    }
}

private final class FakeMenuBarTitleDisplay: MenuBarTitleDisplaying {
    var title = ""
    var font: NSFont?
}
