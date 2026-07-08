# Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Localize the NowThere menu UI into English, Simplified Chinese, and Japanese while keeping the current deterministic menu bar clock output.

**Architecture:** Add app-target `Localizable.strings` resources and a small app-target lookup layer backed by `Bundle.module`. Keep `NowThereCore` free of localization resources; app UI maps core enum values to localized labels. Update the app bundle script so SwiftPM resource bundles are included in `NowThere.app`.

**Tech Stack:** Swift 6, SwiftUI, Foundation `Bundle` and `PropertyListSerialization`, Swift Package Manager resources, XCTest, bash.

## Global Constraints

- Platform target remains macOS 13+.
- Localize visible static text in the menu UI.
- Support English, Simplified Chinese, and Japanese.
- Follow the macOS system language automatically.
- Keep the current menu bar title output such as `Tokyo Jul 08 Wed 12:34`.
- Keep date, weekday, city label, time zone search result text, IANA identifiers, and custom user labels unchanged.
- No in-app language selector.
- No persisted language preference.
- No localization of menu bar date or weekday output.
- No localization of city labels or time zone identifiers.
- No locale-aware 12-hour / 24-hour automatic selection.
- No changes to existing time format, title style, field visibility, or launch-at-login behavior.
- English remains the development and fallback language.
- Every localization key must be present in English, Simplified Chinese, and Japanese.
- `ClockFormatter` continues to default to `Locale(identifier: "en_US_POSIX")`.

---

## File Structure

- `Package.swift`
  - Adds `resources: [.process("Resources")]` to the `NowThere` executable target only.

- `Sources/NowThere/AppLocalization.swift`
  - New app-target localization key list.
  - New runtime lookup through `Bundle.module`.
  - New deterministic test lookup for a specific localization.
  - New app-target menu label helpers for `TitleStyle`, `TimeFormat`, `ClockField`, and launch-at-login errors.

- `Sources/NowThere/Resources/en.lproj/Localizable.strings`
  - English menu strings and fallback copy.

- `Sources/NowThere/Resources/zh-Hans.lproj/Localizable.strings`
  - Simplified Chinese menu strings.

- `Sources/NowThere/Resources/ja.lproj/Localizable.strings`
  - Japanese menu strings.

- `Sources/NowThere/MenuBarContentView.swift`
  - Replaces hard-coded user-facing menu text with `AppLocalization` and `AppMenuLabels`.

- `Sources/NowThereCore/ClockViewModel.swift`
  - Adds a semantic `LaunchAtLoginError` while preserving the existing English compatibility message.

- `scripts/build-app-bundle.sh`
  - Copies SwiftPM `.resources` bundles into `NowThere.app/Contents/Resources`.

- `Tests/NowThereAppTests/AppLocalizationTests.swift`
  - New tests for key coverage and localized label resolution.

- `Tests/NowThereCoreTests/ClockViewModelTests.swift`
  - Updates launch-at-login failure coverage to assert the semantic error state.

---

### Task 1: App Localization Resources and Lookup

**Files:**
- Modify: `Package.swift`
- Create: `Sources/NowThere/AppLocalization.swift`
- Create: `Sources/NowThere/Resources/en.lproj/Localizable.strings`
- Create: `Sources/NowThere/Resources/zh-Hans.lproj/Localizable.strings`
- Create: `Sources/NowThere/Resources/ja.lproj/Localizable.strings`
- Test: `Tests/NowThereAppTests/AppLocalizationTests.swift`

**Interfaces:**
- Consumes: existing `NowThere` executable target and SwiftPM test target `NowThereAppTests`.
- Produces:
  - `enum AppLocalizationKey: String, CaseIterable`
  - `enum AppLocalization`
  - `static let AppLocalization.supportedLocalizations: [String]`
  - `static func AppLocalization.string(_ key: AppLocalizationKey) -> String`
  - `static func AppLocalization.string(_ key: AppLocalizationKey, localization: String) -> String`
  - `static func AppLocalization.strings(for localization: String) -> [String: String]`

- [ ] **Step 1: Write the failing localization resource tests**

Create `Tests/NowThereAppTests/AppLocalizationTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the localization tests and verify failure**

Run:

```bash
swift test --filter AppLocalizationTests
```

Expected: FAIL at compile time with errors like `cannot find 'AppLocalization' in scope` and `cannot find 'AppLocalizationKey' in scope`.

- [ ] **Step 3: Add executable target resources to `Package.swift`**

Change the `NowThere` executable target to:

```swift
        .executableTarget(
            name: "NowThere",
            dependencies: ["NowThereCore"],
            resources: [
                .process("Resources")
            ]
        ),
```

- [ ] **Step 4: Add the localization lookup helper**

Create `Sources/NowThere/AppLocalization.swift`:

```swift
import Foundation

enum AppLocalizationKey: String, CaseIterable {
    case detailsTimeZone = "details.timeZone"
    case detailsDate = "details.date"
    case detailsWeekday = "details.weekday"
    case detailsTime = "details.time"
    case detailsUTCOffset = "details.utcOffset"
    case searchTitle = "search.title"
    case searchPlaceholder = "search.placeholder"
    case searchEmpty = "search.empty"
    case settingsMenuBarFields = "settings.menuBarFields"
    case settingsCustomLabel = "settings.customLabel"
    case settingsCustomLabelPlaceholder = "settings.customLabel.placeholder"
    case settingsTitleStyle = "settings.titleStyle"
    case settingsTitleStyleStandard = "settings.titleStyle.standard"
    case settingsTitleStyleTimeFirst = "settings.titleStyle.timeFirst"
    case settingsTitleStyleSeparated = "settings.titleStyle.separated"
    case settingsTitleStyleBracketed = "settings.titleStyle.bracketed"
    case settingsTimeFormat = "settings.timeFormat"
    case settingsTimeFormatTwentyFourHour = "settings.timeFormat.twentyFourHour"
    case settingsTimeFormatTwelveHour = "settings.timeFormat.twelveHour"
    case settingsFieldCityLabel = "settings.field.cityLabel"
    case settingsFieldDate = "settings.field.date"
    case settingsFieldWeekday = "settings.field.weekday"
    case settingsFieldTime = "settings.field.time"
    case settingsLaunchAtLogin = "settings.launchAtLogin"
    case launchAtLoginErrorUpdateFailed = "launchAtLogin.error.updateFailed"
    case commandQuit = "command.quit"
}

enum AppLocalization {
    static let supportedLocalizations = ["en", "zh-Hans", "ja"]

    static func string(_ key: AppLocalizationKey) -> String {
        Bundle.module.localizedString(
            forKey: key.rawValue,
            value: nil,
            table: "Localizable"
        )
    }

    static func string(_ key: AppLocalizationKey, localization: String) -> String {
        strings(for: localization)[key.rawValue] ?? key.rawValue
    }

    static func strings(for localization: String) -> [String: String] {
        guard let url = Bundle.module.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: localization
        ) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
            return plist as? [String: String] ?? [:]
        } catch {
            return [:]
        }
    }
}
```

- [ ] **Step 5: Add English localization resources**

Create `Sources/NowThere/Resources/en.lproj/Localizable.strings`:

```text
"details.timeZone" = "Time Zone";
"details.date" = "Date";
"details.weekday" = "Weekday";
"details.time" = "Time";
"details.utcOffset" = "UTC Offset";
"search.title" = "Time Zone";
"search.placeholder" = "Search city or time zone";
"search.empty" = "No matching time zones";
"settings.menuBarFields" = "Menu Bar Fields";
"settings.customLabel" = "Custom Label";
"settings.customLabel.placeholder" = "Work, Home, Client";
"settings.titleStyle" = "Title Style";
"settings.titleStyle.standard" = "Default";
"settings.titleStyle.timeFirst" = "Time First";
"settings.titleStyle.separated" = "Separated";
"settings.titleStyle.bracketed" = "Bracketed";
"settings.timeFormat" = "Time Format";
"settings.timeFormat.twentyFourHour" = "24-hour";
"settings.timeFormat.twelveHour" = "12-hour";
"settings.field.cityLabel" = "City/Label";
"settings.field.date" = "Date";
"settings.field.weekday" = "Weekday";
"settings.field.time" = "Time";
"settings.launchAtLogin" = "Launch at Login";
"launchAtLogin.error.updateFailed" = "Could not update launch setting";
"command.quit" = "Quit NowThere";
```

- [ ] **Step 6: Add Simplified Chinese localization resources**

Create `Sources/NowThere/Resources/zh-Hans.lproj/Localizable.strings`:

```text
"details.timeZone" = "时区";
"details.date" = "日期";
"details.weekday" = "星期";
"details.time" = "时间";
"details.utcOffset" = "UTC 偏移";
"search.title" = "时区";
"search.placeholder" = "搜索城市或时区";
"search.empty" = "没有匹配的时区";
"settings.menuBarFields" = "菜单栏字段";
"settings.customLabel" = "自定义标签";
"settings.customLabel.placeholder" = "工作、家庭、客户";
"settings.titleStyle" = "标题样式";
"settings.titleStyle.standard" = "默认";
"settings.titleStyle.timeFirst" = "时间优先";
"settings.titleStyle.separated" = "分隔显示";
"settings.titleStyle.bracketed" = "括号显示";
"settings.timeFormat" = "时间格式";
"settings.timeFormat.twentyFourHour" = "24 小时制";
"settings.timeFormat.twelveHour" = "12 小时制";
"settings.field.cityLabel" = "城市/标签";
"settings.field.date" = "日期";
"settings.field.weekday" = "星期";
"settings.field.time" = "时间";
"settings.launchAtLogin" = "登录时启动";
"launchAtLogin.error.updateFailed" = "无法更新启动设置";
"command.quit" = "退出 NowThere";
```

- [ ] **Step 7: Add Japanese localization resources**

Create `Sources/NowThere/Resources/ja.lproj/Localizable.strings`:

```text
"details.timeZone" = "タイムゾーン";
"details.date" = "日付";
"details.weekday" = "曜日";
"details.time" = "時刻";
"details.utcOffset" = "UTC オフセット";
"search.title" = "タイムゾーン";
"search.placeholder" = "都市またはタイムゾーンを検索";
"search.empty" = "一致するタイムゾーンがありません";
"settings.menuBarFields" = "メニューバー項目";
"settings.customLabel" = "カスタムラベル";
"settings.customLabel.placeholder" = "仕事、自宅、クライアント";
"settings.titleStyle" = "タイトルスタイル";
"settings.titleStyle.standard" = "デフォルト";
"settings.titleStyle.timeFirst" = "時刻を先頭";
"settings.titleStyle.separated" = "区切り表示";
"settings.titleStyle.bracketed" = "括弧付き";
"settings.timeFormat" = "時刻形式";
"settings.timeFormat.twentyFourHour" = "24時間";
"settings.timeFormat.twelveHour" = "12時間";
"settings.field.cityLabel" = "都市/ラベル";
"settings.field.date" = "日付";
"settings.field.weekday" = "曜日";
"settings.field.time" = "時刻";
"settings.launchAtLogin" = "ログイン時に起動";
"launchAtLogin.error.updateFailed" = "起動設定を更新できませんでした";
"command.quit" = "NowThere を終了";
```

- [ ] **Step 8: Run the localization tests and verify they pass**

Run:

```bash
swift test --filter AppLocalizationTests
```

Expected: PASS with `AppLocalizationTests` passing.

- [ ] **Step 9: Commit Task 1**

```bash
git add Package.swift Sources/NowThere/AppLocalization.swift Sources/NowThere/Resources Tests/NowThereAppTests/AppLocalizationTests.swift
git commit -m "feat: add app localization resources" -m "AI-Co-Authored-By: Codex"
```

---

### Task 2: Localized Menu Labels and SwiftUI Wiring

**Files:**
- Modify: `Sources/NowThere/AppLocalization.swift`
- Modify: `Sources/NowThere/MenuBarContentView.swift`
- Test: `Tests/NowThereAppTests/AppLocalizationTests.swift`

**Interfaces:**
- Consumes:
  - `AppLocalization.string(_:)`
  - `AppLocalization.string(_:localization:)`
  - `TitleStyle`
  - `TimeFormat`
  - `ClockField`
- Produces:
  - `enum AppMenuLabels`
  - `static func AppMenuLabels.titleStyleName(_ titleStyle: TitleStyle) -> String`
  - `static func AppMenuLabels.titleStyleName(_ titleStyle: TitleStyle, localization: String) -> String`
  - `static func AppMenuLabels.timeFormatName(_ timeFormat: TimeFormat) -> String`
  - `static func AppMenuLabels.timeFormatName(_ timeFormat: TimeFormat, localization: String) -> String`
  - `static func AppMenuLabels.clockFieldName(_ field: ClockField) -> String`
  - `static func AppMenuLabels.clockFieldName(_ field: ClockField, localization: String) -> String`

- [ ] **Step 1: Write failing menu label helper tests**

Append these tests to `Tests/NowThereAppTests/AppLocalizationTests.swift`:

```swift
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
```

Also add this import at the top of the file:

```swift
@testable import NowThereCore
```

- [ ] **Step 2: Run the app localization tests and verify failure**

Run:

```bash
swift test --filter AppLocalizationTests
```

Expected: FAIL at compile time with `cannot find 'AppMenuLabels' in scope`.

- [ ] **Step 3: Add menu label helpers**

Update the imports at the top of `Sources/NowThere/AppLocalization.swift`:

```swift
import Foundation
import NowThereCore
```

Then append this to `Sources/NowThere/AppLocalization.swift`:

```swift

enum AppMenuLabels {
    static func titleStyleName(_ titleStyle: TitleStyle) -> String {
        AppLocalization.string(localizationKey(for: titleStyle))
    }

    static func titleStyleName(_ titleStyle: TitleStyle, localization: String) -> String {
        AppLocalization.string(localizationKey(for: titleStyle), localization: localization)
    }

    static func timeFormatName(_ timeFormat: TimeFormat) -> String {
        AppLocalization.string(localizationKey(for: timeFormat))
    }

    static func timeFormatName(_ timeFormat: TimeFormat, localization: String) -> String {
        AppLocalization.string(localizationKey(for: timeFormat), localization: localization)
    }

    static func clockFieldName(_ field: ClockField) -> String {
        AppLocalization.string(localizationKey(for: field))
    }

    static func clockFieldName(_ field: ClockField, localization: String) -> String {
        AppLocalization.string(localizationKey(for: field), localization: localization)
    }

    private static func localizationKey(for titleStyle: TitleStyle) -> AppLocalizationKey {
        switch titleStyle {
        case .standard:
            .settingsTitleStyleStandard
        case .timeFirst:
            .settingsTitleStyleTimeFirst
        case .separated:
            .settingsTitleStyleSeparated
        case .bracketed:
            .settingsTitleStyleBracketed
        }
    }

    private static func localizationKey(for timeFormat: TimeFormat) -> AppLocalizationKey {
        switch timeFormat {
        case .twentyFourHour:
            .settingsTimeFormatTwentyFourHour
        case .twelveHour:
            .settingsTimeFormatTwelveHour
        }
    }

    private static func localizationKey(for field: ClockField) -> AppLocalizationKey {
        switch field {
        case .city:
            .settingsFieldCityLabel
        case .date:
            .settingsFieldDate
        case .weekday:
            .settingsFieldWeekday
        case .time:
            .settingsFieldTime
        }
    }
}
```

- [ ] **Step 4: Replace hard-coded menu strings**

Update `Sources/NowThere/MenuBarContentView.swift` with these replacements:

```swift
            Button(AppLocalization.string(.commandQuit)) {
                NSApplication.shared.terminate(nil)
            }
```

```swift
            detailRow(label: AppLocalization.string(.detailsTimeZone), value: details.identifier)
            detailRow(label: AppLocalization.string(.detailsDate), value: details.fullDate)
            detailRow(label: AppLocalization.string(.detailsWeekday), value: details.fullWeekday)
            detailRow(label: AppLocalization.string(.detailsTime), value: details.time)
            detailRow(label: AppLocalization.string(.detailsUTCOffset), value: details.utcOffset)
```

```swift
            Text(AppLocalization.string(.searchTitle))
                .font(.headline)

            TextField(AppLocalization.string(.searchPlaceholder), text: $searchText)
                .textFieldStyle(.roundedBorder)
```

```swift
                Text(AppLocalization.string(.searchEmpty))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
```

```swift
            Text(AppLocalization.string(.settingsMenuBarFields))
                .font(.headline)

            HStack {
                Text(AppLocalization.string(.settingsCustomLabel))
                Spacer()
                TextField(
                    AppLocalization.string(.settingsCustomLabelPlaceholder),
                    text: Binding(
                        get: { viewModel.customLabel },
                        set: { viewModel.setCustomLabel($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 190)
            }
```

```swift
            Picker(AppLocalization.string(.settingsTitleStyle), selection: Binding(
                get: { viewModel.titleStyle },
                set: { viewModel.setTitleStyle($0) }
            )) {
                ForEach(TitleStyle.allCases) { titleStyle in
                    Text(AppMenuLabels.titleStyleName(titleStyle))
                        .tag(titleStyle)
                }
            }
            .pickerStyle(.menu)

            Picker(AppLocalization.string(.settingsTimeFormat), selection: Binding(
                get: { viewModel.timeFormat },
                set: { viewModel.setTimeFormat($0) }
            )) {
                ForEach(TimeFormat.allCases) { timeFormat in
                    Text(AppMenuLabels.timeFormatName(timeFormat))
                        .tag(timeFormat)
                }
            }
            .pickerStyle(.menu)
```

```swift
            Toggle(AppMenuLabels.clockFieldName(.city), isOn: fieldBinding(.city))
            Toggle(AppMenuLabels.clockFieldName(.date), isOn: fieldBinding(.date))
            Toggle(AppMenuLabels.clockFieldName(.weekday), isOn: fieldBinding(.weekday))
            Toggle(AppMenuLabels.clockFieldName(.time), isOn: fieldBinding(.time))
```

```swift
            Toggle(AppLocalization.string(.settingsLaunchAtLogin), isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            ))
```

Leave this existing error message block unchanged until Task 3:

```swift
            if let message = viewModel.launchAtLoginErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
```

- [ ] **Step 5: Run app localization tests and verify they pass**

Run:

```bash
swift test --filter AppLocalizationTests
```

Expected: PASS with all `AppLocalizationTests` passing.

- [ ] **Step 6: Run app tests to catch SwiftUI compile issues**

Run:

```bash
swift test --filter NowThereAppTests
```

Expected: PASS.

- [ ] **Step 7: Commit Task 2**

```bash
git add Sources/NowThere/AppLocalization.swift Sources/NowThere/MenuBarContentView.swift Tests/NowThereAppTests/AppLocalizationTests.swift
git commit -m "feat: localize menu labels" -m "AI-Co-Authored-By: Codex"
```

---

### Task 3: Localized Launch-at-Login Error Display

**Files:**
- Modify: `Sources/NowThereCore/ClockViewModel.swift`
- Modify: `Sources/NowThere/AppLocalization.swift`
- Modify: `Sources/NowThere/MenuBarContentView.swift`
- Modify: `Tests/NowThereCoreTests/ClockViewModelTests.swift`
- Modify: `Tests/NowThereAppTests/AppLocalizationTests.swift`

**Interfaces:**
- Consumes:
  - existing `ClockViewModel.setLaunchAtLogin(_:)`
  - existing `launchAtLogin.error.updateFailed` localization key
- Produces:
  - `public enum LaunchAtLoginError: Equatable, Sendable`
  - `@Published public private(set) var ClockViewModel.launchAtLoginError: LaunchAtLoginError?`
  - compatibility computed property `public var ClockViewModel.launchAtLoginErrorMessage: String?`
  - `static func AppMenuLabels.launchAtLoginErrorMessage(_ error: LaunchAtLoginError) -> String`
  - `static func AppMenuLabels.launchAtLoginErrorMessage(_ error: LaunchAtLoginError, localization: String) -> String`

- [ ] **Step 1: Write failing semantic error tests**

Update `testLaunchAtLoginFailureRollsBackToActualStateAndShowsMessage()` in `Tests/NowThereCoreTests/ClockViewModelTests.swift`:

```swift
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
        XCTAssertEqual(viewModel.launchAtLoginError, .updateFailed)
        XCTAssertEqual(viewModel.launchAtLoginErrorMessage, "Could not update launch setting")
    }
```

Append this test to `Tests/NowThereAppTests/AppLocalizationTests.swift`:

```swift
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
```

- [ ] **Step 2: Run targeted tests and verify failure**

Run:

```bash
swift test --filter ClockViewModelTests/testLaunchAtLoginFailureRollsBackToActualStateAndShowsMessage
swift test --filter AppLocalizationTests/testLaunchAtLoginErrorLabelsResolveInSupportedLocalizations
```

Expected: FAIL at compile time because `launchAtLoginError`, `LaunchAtLoginError.updateFailed`, and `AppMenuLabels.launchAtLoginErrorMessage` do not exist yet.

- [ ] **Step 3: Add semantic launch-at-login error state**

In `Sources/NowThereCore/ClockViewModel.swift`, add this enum near `LoginItemManaging`:

```swift
public enum LaunchAtLoginError: Equatable, Sendable {
    case updateFailed
}
```

Replace this property:

```swift
    @Published public private(set) var launchAtLoginErrorMessage: String?
```

with:

```swift
    @Published public private(set) var launchAtLoginError: LaunchAtLoginError?

    public var launchAtLoginErrorMessage: String? {
        guard launchAtLoginError != nil else {
            return nil
        }

        return "Could not update launch setting"
    }
```

In the initializer, replace:

```swift
        self.launchAtLoginErrorMessage = nil
```

with:

```swift
        self.launchAtLoginError = nil
```

Update `setLaunchAtLogin(_:)`:

```swift
    public func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginError = nil
        } catch {
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginError = .updateFailed
        }
    }
```

- [ ] **Step 4: Add localized app labels for launch-at-login errors**

Append these methods inside `AppMenuLabels` in `Sources/NowThere/AppLocalization.swift`:

```swift
    static func launchAtLoginErrorMessage(_ error: LaunchAtLoginError) -> String {
        AppLocalization.string(localizationKey(for: error))
    }

    static func launchAtLoginErrorMessage(
        _ error: LaunchAtLoginError,
        localization: String
    ) -> String {
        AppLocalization.string(localizationKey(for: error), localization: localization)
    }
```

Append this private key mapper inside `AppMenuLabels`:

```swift
    private static func localizationKey(for error: LaunchAtLoginError) -> AppLocalizationKey {
        switch error {
        case .updateFailed:
            .launchAtLoginErrorUpdateFailed
        }
    }
```

- [ ] **Step 5: Use localized launch-at-login errors in the menu**

In `Sources/NowThere/MenuBarContentView.swift`, replace:

```swift
            if let message = viewModel.launchAtLoginErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
```

with:

```swift
            if let error = viewModel.launchAtLoginError {
                Text(AppMenuLabels.launchAtLoginErrorMessage(error))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
```

- [ ] **Step 6: Run targeted tests and verify they pass**

Run:

```bash
swift test --filter ClockViewModelTests/testLaunchAtLoginFailureRollsBackToActualStateAndShowsMessage
swift test --filter AppLocalizationTests/testLaunchAtLoginErrorLabelsResolveInSupportedLocalizations
```

Expected: PASS.

- [ ] **Step 7: Run core and app tests**

Run:

```bash
swift test --filter NowThereCoreTests
swift test --filter NowThereAppTests
```

Expected: PASS.

- [ ] **Step 8: Commit Task 3**

```bash
git add Sources/NowThereCore/ClockViewModel.swift Sources/NowThere/AppLocalization.swift Sources/NowThere/MenuBarContentView.swift Tests/NowThereCoreTests/ClockViewModelTests.swift Tests/NowThereAppTests/AppLocalizationTests.swift
git commit -m "feat: localize launch error display" -m "AI-Co-Authored-By: Codex"
```

---

### Task 4: App Bundle Resource Packaging and Full Verification

**Files:**
- Modify: `scripts/build-app-bundle.sh`

**Interfaces:**
- Consumes:
  - `swift build --configuration "$CONFIGURATION" --product NowThere`
  - SwiftPM-generated `*.resources` directories in the Swift build output directory.
- Produces:
  - Packaged `NowThere.app/Contents/Resources/*.resources/.../Localizable.strings` files.

- [ ] **Step 1: Run the failing app bundle resource check**

Run:

```bash
scripts/build-app-bundle.sh debug
test -n "$(find .build/debug/NowThere.app/Contents/Resources -path '*zh-Hans.lproj/Localizable.strings' -print -quit)"
```

Expected: FAIL on the `test -n` command because the current script does not copy SwiftPM resource bundles into the `.app`.

- [ ] **Step 2: Copy SwiftPM resource bundles into the app bundle**

Update `scripts/build-app-bundle.sh` to:

```bash
#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-debug}"

swift build --configuration "$CONFIGURATION" --product NowThere
BUILD_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
APP_DIR=".build/${CONFIGURATION}/NowThere.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
cp "$BUILD_DIR/NowThere" "$APP_DIR/Contents/MacOS/NowThere"
chmod +x "$APP_DIR/Contents/MacOS/NowThere"

for RESOURCE_BUNDLE in "$BUILD_DIR"/*.resources; do
    [ -d "$RESOURCE_BUNDLE" ] || continue
    cp -R "$RESOURCE_BUNDLE" "$APP_DIR/Contents/Resources/"
done

echo "$APP_DIR"
```

- [ ] **Step 3: Re-run the app bundle resource check**

Run:

```bash
scripts/build-app-bundle.sh debug
test -n "$(find .build/debug/NowThere.app/Contents/Resources -path '*en.lproj/Localizable.strings' -print -quit)"
test -n "$(find .build/debug/NowThere.app/Contents/Resources -path '*zh-Hans.lproj/Localizable.strings' -print -quit)"
test -n "$(find .build/debug/NowThere.app/Contents/Resources -path '*ja.lproj/Localizable.strings' -print -quit)"
```

Expected: PASS for all three `test -n` commands.

- [ ] **Step 4: Run the full test suite**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 5: Confirm menu bar formatter output remains unchanged**

Run:

```bash
swift test --filter ClockFormatterTests/testTitleUsesEnglishShortFormatForTokyo
swift test --filter MenuBarTitleTests/testMenuBarLabelUsesVisibleClockTitleText
```

Expected: PASS with expected title output still `Tokyo Jul 08 Wed 12:34`.

- [ ] **Step 6: Commit Task 4**

```bash
git add scripts/build-app-bundle.sh
git commit -m "fix: package localization resources in app bundle" -m "AI-Co-Authored-By: Codex"
```

---

## Final Verification

- [ ] Run the complete test suite:

```bash
swift test
```

- [ ] Build the app bundle:

```bash
scripts/build-app-bundle.sh debug
```

- [ ] Verify the bundle contains all localization resources:

```bash
find .build/debug/NowThere.app/Contents/Resources -name Localizable.strings | sort
```

Expected output includes paths ending in:

```text
en.lproj/Localizable.strings
ja.lproj/Localizable.strings
zh-Hans.lproj/Localizable.strings
```

- [ ] Confirm the working tree is clean except for intentional untracked build artifacts ignored by git:

```bash
git status --short
```

Expected: no tracked file changes.
