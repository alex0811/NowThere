# Time Format Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted 12-hour / 24-hour time format setting that updates both the NowThere menu bar title and the menu detail `Time` row.

**Architecture:** Add a small `TimeFormat` enum to `NowThereCore`, pass it through `ClockFormatter`, persist it with `TimeZoneStore`, expose it from `ClockViewModel`, and bind it to a SwiftUI picker in the existing menu. The default remains 24-hour so existing output is preserved until the user changes the setting.

**Tech Stack:** Swift 6, SwiftUI, Foundation `DateFormatter` and `UserDefaults`, XCTest, Swift Package Manager.

## Global Constraints

- Platform target remains macOS 13+.
- Default time format is `24-hour`.
- Supported formats are `24-hour` and `12-hour`.
- `24-hour` examples: `00:05`, `09:05`, `21:05`.
- `12-hour` examples: `12:05 AM`, `9:05 AM`, `9:05 PM`.
- The selected format affects both the menu bar title and the menu detail `Time` row.
- No automatic following of the macOS system time format.
- No separate time format settings for the menu bar title and detail row.
- No seconds display.
- No custom free-form date/time template.
- Existing title styles, field visibility toggles, custom label behavior, UTC offset, and time zone search behavior remain unchanged.

---

## File Structure

- `Sources/NowThereCore/TimeFormat.swift`
  - New core enum for the persisted time format and menu display labels.

- `Sources/NowThereCore/ClockFormatter.swift`
  - Adds a `timeFormat` parameter to title and detail formatting.
  - Keeps default arguments at `.twentyFourHour` to preserve current callers.

- `Sources/NowThereCore/TimeZoneStore.swift`
  - Adds `timeFormat` storage key.
  - Adds `loadTimeFormat()` and `saveTimeFormat(_:)`.
  - Rewrites invalid saved values to `.twentyFourHour`.

- `Sources/NowThereCore/ClockViewModel.swift`
  - Adds published `timeFormat`.
  - Loads the stored format at startup.
  - Refreshes the title and details when the format changes.

- `Sources/NowThere/MenuBarContentView.swift`
  - Adds a `Time Format` picker near the existing `Title Style` picker.

- `Tests/NowThereCoreTests/ClockFormatterTests.swift`
  - Covers 12-hour title output, 12-hour detail output, and edge cases for midnight and single-digit hours.

- `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
  - Covers default, save/load, and invalid stored format rewrite.

- `Tests/NowThereCoreTests/ClockViewModelTests.swift`
  - Covers initial load from store and runtime format changes.

---

### Task 1: Core Formatter Time Format

**Files:**
- Create: `Sources/NowThereCore/TimeFormat.swift`
- Modify: `Sources/NowThereCore/ClockFormatter.swift`
- Test: `Tests/NowThereCoreTests/ClockFormatterTests.swift`

**Interfaces:**
- Consumes: Existing `ClockFormatter.title(for:timeZone:visibility:customLabel:titleStyle:)` and `ClockFormatter.details(for:timeZone:)`.
- Produces:
  - `public enum TimeFormat: String, CaseIterable, Identifiable, Equatable, Sendable`
  - `public var TimeFormat.id: String`
  - `public var TimeFormat.displayName: String`
  - `public var TimeFormat.dateFormat: String`
  - `ClockFormatter.title(for: Date, timeZone: TimeZone, visibility: FieldVisibility, customLabel: String, titleStyle: TitleStyle, timeFormat: TimeFormat) -> String`
  - `ClockFormatter.details(for: Date, timeZone: TimeZone, timeFormat: TimeFormat) -> ClockDetails`

- [ ] **Step 1: Write failing formatter tests**

Add these tests to `Tests/NowThereCoreTests/ClockFormatterTests.swift` before `testDetailsIncludeFullDateWeekdayTimeAndOffset()`:

```swift
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
```

- [ ] **Step 2: Run formatter tests and verify failure**

Run:

```bash
swift test --filter ClockFormatterTests
```

Expected: FAIL because `timeFormat` and `TimeFormat.twelveHour` are not implemented yet.

- [ ] **Step 3: Add the time format enum**

Create `Sources/NowThereCore/TimeFormat.swift`:

```swift
import Foundation

public enum TimeFormat: String, CaseIterable, Identifiable, Equatable, Sendable {
    case twentyFourHour
    case twelveHour

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .twentyFourHour:
            "24-hour"
        case .twelveHour:
            "12-hour"
        }
    }

    public var dateFormat: String {
        switch self {
        case .twentyFourHour:
            "HH:mm"
        case .twelveHour:
            "h:mm a"
        }
    }
}
```

- [ ] **Step 4: Thread time format through `ClockFormatter`**

Update `ClockFormatter.title(...)` to accept:

```swift
        titleStyle: TitleStyle = .standard,
        timeFormat: TimeFormat = .twentyFourHour
```

Change the time part line to:

```swift
        let timePart = visibility.showsTime ? format(date, format: timeFormat.dateFormat, timeZone: timeZone) : nil
```

Update `ClockFormatter.details(...)` to:

```swift
    public func details(
        for date: Date,
        timeZone: TimeZone,
        timeFormat: TimeFormat = .twentyFourHour
    ) -> ClockDetails {
        ClockDetails(
            label: cityLabel(for: timeZone),
            identifier: timeZone.identifier,
            fullDate: format(date, format: "MMMM d, yyyy", timeZone: timeZone),
            fullWeekday: format(date, format: "EEEE", timeZone: timeZone),
            time: format(date, format: timeFormat.dateFormat, timeZone: timeZone),
            utcOffset: utcOffset(for: date, timeZone: timeZone)
        )
    }
```

- [ ] **Step 5: Run formatter tests and verify pass**

Run:

```bash
swift test --filter ClockFormatterTests
```

Expected: PASS.

- [ ] **Step 6: Commit formatter support**

Run:

```bash
git add Sources/NowThereCore/TimeFormat.swift Sources/NowThereCore/ClockFormatter.swift Tests/NowThereCoreTests/ClockFormatterTests.swift
git commit -m "feat: add time format formatter support" -m "AI-Co-Authored-By: Codex"
```

---

### Task 2: Persist Time Format and Expose It From the View Model

**Files:**
- Modify: `Sources/NowThereCore/TimeZoneStore.swift`
- Modify: `Sources/NowThereCore/ClockViewModel.swift`
- Test: `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
- Test: `Tests/NowThereCoreTests/ClockViewModelTests.swift`

**Interfaces:**
- Consumes: `TimeFormat`, formatter `timeFormat` parameters from Task 1.
- Produces:
  - `TimeZoneStoreKeys.timeFormat`
  - `public func TimeZoneStore.loadTimeFormat() -> TimeFormat`
  - `public func TimeZoneStore.saveTimeFormat(_ timeFormat: TimeFormat)`
  - `@Published public private(set) var ClockViewModel.timeFormat: TimeFormat`
  - `public func ClockViewModel.setTimeFormat(_ timeFormat: TimeFormat)`

- [ ] **Step 1: Write failing store tests**

Add these tests to `Tests/NowThereCoreTests/TimeZoneStoreTests.swift` after `testLoadTitleStyleRewritesInvalidSavedValueToStandard()`:

```swift
    func testLoadTimeFormatDefaultsToTwentyFourHour() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        XCTAssertEqual(store.loadTimeFormat(), .twentyFourHour)
    }

    func testSaveTimeFormatPersistsValue() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        store.saveTimeFormat(.twelveHour)

        XCTAssertEqual(store.loadTimeFormat(), .twelveHour)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.timeFormat), "twelveHour")
    }

    func testLoadTimeFormatRewritesInvalidSavedValueToTwentyFourHour() {
        let defaults = makeDefaults()
        defaults.set("system", forKey: TimeZoneStoreKeys.timeFormat)
        let store = TimeZoneStore(defaults: defaults)

        let loaded = store.loadTimeFormat()

        XCTAssertEqual(loaded, .twentyFourHour)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.timeFormat), TimeFormat.twentyFourHour.rawValue)
    }
```

- [ ] **Step 2: Write failing view model tests**

Add these tests to `Tests/NowThereCoreTests/ClockViewModelTests.swift` after `testSettingTitleStylePersistsAndRefreshesTitle()`:

```swift
    func testInitialStateUsesStoredTimeFormat() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveTimeFormat(.twelveHour)
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)

        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(viewModel.timeFormat, .twelveHour)
        XCTAssertEqual(viewModel.menuTitle, "Tokyo Jul 08 Wed 12:34 PM")
        XCTAssertEqual(viewModel.details.time, "12:34 PM")
    }

    func testSettingTimeFormatPersistsAndRefreshesTitleAndDetails() throws {
        let defaults = makeDefaults()
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { tokyo })
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        viewModel.setTimeFormat(.twelveHour)

        XCTAssertEqual(viewModel.timeFormat, .twelveHour)
        XCTAssertEqual(viewModel.menuTitle, "Tokyo Jul 08 Wed 12:34 PM")
        XCTAssertEqual(viewModel.details.time, "12:34 PM")
        XCTAssertEqual(store.loadTimeFormat(), .twelveHour)
    }
```

- [ ] **Step 3: Run store and view model tests and verify failure**

Run:

```bash
swift test --filter TimeZoneStoreTests
swift test --filter ClockViewModelTests
```

Expected: FAIL because store and view model APIs are not implemented yet.

- [ ] **Step 4: Add store persistence**

Update `TimeZoneStoreKeys`:

```swift
    static let timeFormat = "timeFormat"
```

Add these methods to `TimeZoneStore` after `saveTitleStyle(_:)`:

```swift
    public func loadTimeFormat() -> TimeFormat {
        guard let savedValue = defaults.string(forKey: TimeZoneStoreKeys.timeFormat) else {
            return .twentyFourHour
        }

        guard let timeFormat = TimeFormat(rawValue: savedValue) else {
            saveTimeFormat(.twentyFourHour)
            return .twentyFourHour
        }

        return timeFormat
    }

    public func saveTimeFormat(_ timeFormat: TimeFormat) {
        defaults.set(timeFormat.rawValue, forKey: TimeZoneStoreKeys.timeFormat)
    }
```

- [ ] **Step 5: Add view model state and refresh behavior**

Add the published property near `titleStyle`:

```swift
    @Published public private(set) var timeFormat: TimeFormat
```

Load it in the initializer:

```swift
        let loadedTimeFormat = store.loadTimeFormat()
```

Assign it:

```swift
        self.timeFormat = loadedTimeFormat
```

Pass it into the initial title:

```swift
            titleStyle: loadedTitleStyle,
            timeFormat: loadedTimeFormat
```

Update `details`:

```swift
    public var details: ClockDetails {
        formatter.details(for: now, timeZone: selectedTimeZone, timeFormat: timeFormat)
    }
```

Pass it in `refresh()`:

```swift
            titleStyle: titleStyle,
            timeFormat: timeFormat
```

Add the setter after `setTitleStyle(_:)`:

```swift
    public func setTimeFormat(_ timeFormat: TimeFormat) {
        self.timeFormat = timeFormat
        store.saveTimeFormat(timeFormat)
        refresh()
    }
```

- [ ] **Step 6: Run store and view model tests and verify pass**

Run:

```bash
swift test --filter TimeZoneStoreTests
swift test --filter ClockViewModelTests
```

Expected: PASS.

- [ ] **Step 7: Commit persistence and view model support**

Run:

```bash
git add Sources/NowThereCore/TimeZoneStore.swift Sources/NowThereCore/ClockViewModel.swift Tests/NowThereCoreTests/TimeZoneStoreTests.swift Tests/NowThereCoreTests/ClockViewModelTests.swift
git commit -m "feat: persist time format setting" -m "AI-Co-Authored-By: Codex"
```

---

### Task 3: Add Menu Picker and Full Verification

**Files:**
- Modify: `Sources/NowThere/MenuBarContentView.swift`
- Test: `Tests/NowThereAppTests/MenuBarTitleTests.swift`

**Interfaces:**
- Consumes: `TimeFormat.allCases`, `TimeFormat.displayName`, `ClockViewModel.timeFormat`, and `ClockViewModel.setTimeFormat(_:)`.
- Produces: A `Time Format` picker in the existing `Menu Bar Fields` section.

- [ ] **Step 1: Add app-level title regression test**

Add this test to `Tests/NowThereAppTests/MenuBarTitleTests.swift` after `testMenuBarLabelIncludesCustomLabelFromViewModel()`:

```swift
    func testMenuBarLabelUsesStoredTwelveHourTimeFormat() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveTimeFormat(.twelveHour)

        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(NowThereMenuBarLabel.title(for: viewModel), "Tokyo Jul 08 Wed 12:34 PM")
    }
```

- [ ] **Step 2: Run app title tests**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: PASS after Task 2 because the formatter pipeline already supports the new format. If it fails, fix the core pipeline before changing UI.

- [ ] **Step 3: Add the SwiftUI picker**

In `Sources/NowThere/MenuBarContentView.swift`, add this picker after the existing `Title Style` picker:

```swift
            Picker("Time Format", selection: Binding(
                get: { viewModel.timeFormat },
                set: { viewModel.setTimeFormat($0) }
            )) {
                ForEach(TimeFormat.allCases) { timeFormat in
                    Text(timeFormat.displayName)
                        .tag(timeFormat)
                }
            }
            .pickerStyle(.menu)
```

- [ ] **Step 4: Run focused app tests**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: PASS.

- [ ] **Step 5: Run full verification**

Run:

```bash
swift test
swift build --product NowThere
```

Expected: PASS for both commands.

- [ ] **Step 6: Commit menu picker**

Run:

```bash
git add Sources/NowThere/MenuBarContentView.swift Tests/NowThereAppTests/MenuBarTitleTests.swift
git commit -m "feat: add time format picker" -m "AI-Co-Authored-By: Codex"
```
