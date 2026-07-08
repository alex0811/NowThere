import XCTest
@testable import NowThere
@testable import NowThereCore

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

    func testTitleStyleLabelsResolveInSupportedLocalizations() {
        XCTAssertEqual(AppMenuLabels.titleStyleName(.standard, localization: "en"), "Default")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.timeFirst, localization: "en"), "Time First")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.separated, localization: "en"), "Separated")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.bracketed, localization: "en"), "Bracketed")

        XCTAssertEqual(AppMenuLabels.titleStyleName(.standard, localization: "zh-Hans"), "默认")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.timeFirst, localization: "zh-Hans"), "时间优先")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.separated, localization: "zh-Hans"), "分隔显示")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.bracketed, localization: "zh-Hans"), "括号显示")

        XCTAssertEqual(AppMenuLabels.titleStyleName(.standard, localization: "ja"), "デフォルト")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.timeFirst, localization: "ja"), "時刻を先頭")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.separated, localization: "ja"), "区切り表示")
        XCTAssertEqual(AppMenuLabels.titleStyleName(.bracketed, localization: "ja"), "括弧付き")
    }

    func testTimeFormatLabelsResolveInSupportedLocalizations() {
        XCTAssertEqual(AppMenuLabels.timeFormatName(.twentyFourHour, localization: "en"), "24-hour")
        XCTAssertEqual(AppMenuLabels.timeFormatName(.twelveHour, localization: "en"), "12-hour")

        XCTAssertEqual(AppMenuLabels.timeFormatName(.twentyFourHour, localization: "zh-Hans"), "24 小时制")
        XCTAssertEqual(AppMenuLabels.timeFormatName(.twelveHour, localization: "zh-Hans"), "12 小时制")

        XCTAssertEqual(AppMenuLabels.timeFormatName(.twentyFourHour, localization: "ja"), "24時間")
        XCTAssertEqual(AppMenuLabels.timeFormatName(.twelveHour, localization: "ja"), "12時間")
    }

    func testClockFieldLabelsResolveInSupportedLocalizations() {
        XCTAssertEqual(AppMenuLabels.clockFieldName(.city, localization: "en"), "City/Label")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.date, localization: "en"), "Date")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.weekday, localization: "en"), "Weekday")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.time, localization: "en"), "Time")

        XCTAssertEqual(AppMenuLabels.clockFieldName(.city, localization: "zh-Hans"), "城市/标签")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.date, localization: "zh-Hans"), "日期")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.weekday, localization: "zh-Hans"), "星期")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.time, localization: "zh-Hans"), "时间")

        XCTAssertEqual(AppMenuLabels.clockFieldName(.city, localization: "ja"), "都市/ラベル")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.date, localization: "ja"), "日付")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.weekday, localization: "ja"), "曜日")
        XCTAssertEqual(AppMenuLabels.clockFieldName(.time, localization: "ja"), "時刻")
    }

    func testLaunchAtLoginErrorLabelsResolveInSupportedLocalizations() {
        XCTAssertEqual(
            AppMenuLabels.launchAtLoginErrorMessage(.updateFailed, localization: "en"),
            "Could not update launch setting"
        )
        XCTAssertEqual(
            AppMenuLabels.launchAtLoginErrorMessage(.updateFailed, localization: "zh-Hans"),
            "无法更新启动设置"
        )
        XCTAssertEqual(
            AppMenuLabels.launchAtLoginErrorMessage(.updateFailed, localization: "ja"),
            "起動設定を更新できませんでした"
        )
    }
}
