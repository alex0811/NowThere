import XCTest
@testable import NowThereCore

final class ClockFormatterTests: XCTestCase {
    func testTitleUsesEnglishShortFormatForTokyo() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(for: date, timeZone: tokyo, visibility: .allVisible, customLabel: "")

        XCTAssertEqual(title, "Tokyo Jul 08 Wed 12:34")
    }

    func testTitleUsesChineseShortDateWithoutSpace() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "",
            locale: Locale(identifier: "zh-Hans")
        )

        XCTAssertEqual(title, "Tokyo 7月8日 周三 12:34")
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

        let title = formatter.title(for: date, timeZone: tokyo, visibility: visibility, customLabel: "")

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

        let title = formatter.title(for: date, timeZone: tokyo, visibility: visibility, customLabel: "")

        XCTAssertEqual(title, "NowThere")
    }

    func testTitleShowsCustomLabelBeforeCity() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "  Work  "
        )

        XCTAssertEqual(title, "Work Tokyo Jul 08 Wed 12:34")
    }

    func testTitleTrimsAndHidesWhitespaceOnlyCustomLabel() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "   "
        )

        XCTAssertEqual(title, "Tokyo Jul 08 Wed 12:34")
    }

    func testTitleSupportsTimeFirstStyle() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "",
            titleStyle: .timeFirst
        )

        XCTAssertEqual(title, "12:34 Tokyo Jul 08 Wed")
    }

    func testTitleSupportsSeparatedStyle() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "",
            titleStyle: .separated
        )

        XCTAssertEqual(title, "12:34 | Tokyo Jul 08 Wed")
    }

    func testTitleSupportsBracketedStyle() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "",
            titleStyle: .bracketed
        )

        XCTAssertEqual(title, "[12:34] Tokyo Jul 08 Wed")
    }

    func testTimeFocusedStylesFallBackWhenTimeIsHidden() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let visibility = FieldVisibility(
            showsCity: true,
            showsDate: true,
            showsWeekday: true,
            showsTime: false
        )

        XCTAssertEqual(
            formatter.title(
                for: date,
                timeZone: tokyo,
                visibility: visibility,
                customLabel: "",
                titleStyle: .timeFirst
            ),
            "Tokyo Jul 08 Wed"
        )
        XCTAssertEqual(
            formatter.title(
                for: date,
                timeZone: tokyo,
                visibility: visibility,
                customLabel: "",
                titleStyle: .separated
            ),
            "Tokyo Jul 08 Wed"
        )
        XCTAssertEqual(
            formatter.title(
                for: date,
                timeZone: tokyo,
                visibility: visibility,
                customLabel: "",
                titleStyle: .bracketed
            ),
            "Tokyo Jul 08 Wed"
        )
    }

    func testTimeFocusedStylesKeepCustomLabelBeforePlaceDetails() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "Work",
            titleStyle: .timeFirst
        )

        XCTAssertEqual(title, "12:34 Work Tokyo Jul 08 Wed")
    }

    func testTitleShowsCustomLabelWhenEveryClockFieldIsHidden() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let visibility = FieldVisibility(
            showsCity: false,
            showsDate: false,
            showsWeekday: false,
            showsTime: false
        )

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: visibility,
            customLabel: "Work"
        )

        XCTAssertEqual(title, "Work")
    }

    func testTitleSupportsTwelveHourTimeFormat() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "",
            timeFormat: .twelveHour
        )

        XCTAssertEqual(title, "Tokyo Jul 08 Wed 12:34 PM")
    }

    func testSeparatedStyleUsesTwelveHourTimeFormat() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: .allVisible,
            customLabel: "",
            titleStyle: .separated,
            timeFormat: .twelveHour
        )

        XCTAssertEqual(title, "12:34 PM | Tokyo Jul 08 Wed")
    }

    func testHiddenTimeFieldIgnoresTimeFormat() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let visibility = FieldVisibility(
            showsCity: true,
            showsDate: true,
            showsWeekday: true,
            showsTime: false
        )

        let title = formatter.title(
            for: date,
            timeZone: tokyo,
            visibility: visibility,
            customLabel: "",
            titleStyle: .timeFirst,
            timeFormat: .twelveHour
        )

        XCTAssertEqual(title, "Tokyo Jul 08 Wed")
    }

    func testDetailsSupportTwelveHourTimeFormat() throws {
        let formatter = ClockFormatter()
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))

        let details = formatter.details(for: date, timeZone: tokyo, timeFormat: .twelveHour)

        XCTAssertEqual(details.time, "12:34 PM")
    }

    func testTwelveHourTimeFormatHandlesMidnightAndSingleDigitHours() throws {
        let formatter = ClockFormatter()
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let midnight = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 0, minute: 5)
        let morning = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 9, minute: 5)
        let evening = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 21, minute: 5)

        XCTAssertEqual(formatter.details(for: midnight, timeZone: utc, timeFormat: .twelveHour).time, "12:05 AM")
        XCTAssertEqual(formatter.details(for: morning, timeZone: utc, timeFormat: .twelveHour).time, "9:05 AM")
        XCTAssertEqual(formatter.details(for: evening, timeZone: utc, timeFormat: .twelveHour).time, "9:05 PM")
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
