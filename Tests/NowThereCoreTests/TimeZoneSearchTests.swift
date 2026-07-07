import XCTest
@testable import NowThereCore

final class TimeZoneSearchTests: XCTestCase {
    func testSearchFindsTimeZoneByCityLabel() {
        let search = TimeZoneSearch(identifiers: [
            "America/New_York",
            "Asia/Tokyo",
            "Europe/London"
        ])

        let results = search.results(matching: "Tokyo")

        XCTAssertEqual(results.map(\.identifier), ["Asia/Tokyo"])
        XCTAssertEqual(results.first?.label, "Tokyo")
    }

    func testSearchFindsTimeZoneByIdentifier() {
        let search = TimeZoneSearch(identifiers: [
            "America/New_York",
            "Asia/Tokyo",
            "Europe/London"
        ])

        let results = search.results(matching: "Asia/Tokyo")

        XCTAssertEqual(results.map(\.identifier), ["Asia/Tokyo"])
    }

    func testSearchReturnsEmptyListWhenNothingMatches() {
        let search = TimeZoneSearch(identifiers: [
            "America/New_York",
            "Asia/Tokyo",
            "Europe/London"
        ])

        let results = search.results(matching: "NoSuchCity")

        XCTAssertTrue(results.isEmpty)
    }

    func testEmptyQueryReturnsSortedLimitedResults() {
        let search = TimeZoneSearch(identifiers: [
            "Europe/London",
            "Asia/Tokyo",
            "America/New_York"
        ])

        let results = search.results(matching: "", limit: 2)

        XCTAssertEqual(results.map(\.identifier), ["America/New_York", "Asia/Tokyo"])
    }
}
