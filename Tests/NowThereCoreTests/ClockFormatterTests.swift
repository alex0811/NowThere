import XCTest
@testable import NowThereCore

final class ClockFormatterTests: XCTestCase {
    func testTitleUsesEnglishShortFormatForTokyo() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(for: date, timeZone: tokyo, visibility: .allVisible)

        XCTAssertEqual(title, "Tokyo Jul 08 Wed 12:34")
    }

    func testTitleRespectsHiddenFields() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let visibility = FieldVisibility(
            showsCity: false,
            showsDate: true,
            showsWeekday: false,
            showsTime: true
        )

        let title = formatter.title(for: date, timeZone: tokyo, visibility: visibility)

        XCTAssertEqual(title, "Jul 08 12:34")
    }

    func testTitleFallsBackToAppNameWhenEveryFieldIsHidden() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let visibility = FieldVisibility(
            showsCity: false,
            showsDate: false,
            showsWeekday: false,
            showsTime: false
        )

        let title = formatter.title(for: date, timeZone: tokyo, visibility: visibility)

        XCTAssertEqual(title, "NowThere")
    }

    func testDetailsIncludeFullDateWeekdayTimeAndOffset() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let details = formatter.details(for: date, timeZone: tokyo)

        XCTAssertEqual(details.label, "Tokyo")
        XCTAssertEqual(details.identifier, "Asia/Tokyo")
        XCTAssertEqual(details.fullDate, "July 8, 2026")
        XCTAssertEqual(details.fullWeekday, "Wednesday")
        XCTAssertEqual(details.time, "12:34")
        XCTAssertEqual(details.utcOffset, "UTC+09:00")
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
