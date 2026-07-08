import XCTest
@testable import NowThere

final class AppLocalizationTests: XCTestCase {
    func testEverySupportedLocalizationContainsEveryExpectedKey() {
        XCTAssertEqual(AppLocalization.supportedLocalizations, ["en", "zh-Hans", "ja"])

        for localization in AppLocalization.supportedLocalizations {
            let strings = AppLocalization.strings(for: localization)
            XCTAssertFalse(strings.isEmpty, "\(localization) strings should load")

            for key in AppLocalizationKey.allCases {
                XCTAssertNotNil(
                    strings[key.rawValue],
                    "\(key.rawValue) missing from \(localization)"
                )
            }
        }
    }

    func testStaticMenuStringsResolveInSupportedLocalizations() {
        XCTAssertEqual(AppLocalization.string(.commandQuit, localization: "en"), "Quit NowThere")
        XCTAssertEqual(AppLocalization.string(.commandQuit, localization: "zh-Hans"), "退出 NowThere")
        XCTAssertEqual(AppLocalization.string(.commandQuit, localization: "ja"), "NowThere を終了")

        XCTAssertEqual(AppLocalization.string(.searchPlaceholder, localization: "en"), "Search city or time zone")
        XCTAssertEqual(AppLocalization.string(.searchPlaceholder, localization: "zh-Hans"), "搜索城市或时区")
        XCTAssertEqual(AppLocalization.string(.searchPlaceholder, localization: "ja"), "都市またはタイムゾーンを検索")
    }
}
