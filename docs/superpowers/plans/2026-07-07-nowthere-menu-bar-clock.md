# NowThere Menu Bar Clock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build NowThere, a native macOS menu bar utility that shows a compact English date, weekday, and time for one selected time zone.

**Architecture:** Use Swift Package Manager for source, tests, and repeatable builds. Put deterministic clock logic in `NowThereCore`, keep SwiftUI menu bar UI in the `NowThere` executable target, and create a small app-bundle script so the final executable runs as an LSUIElement menu bar app.

**Tech Stack:** Swift 6, SwiftUI `MenuBarExtra`, Foundation `TimeZone`/`DateFormatter`, `UserDefaults`, ServiceManagement `SMAppService`, XCTest, Swift Package Manager.

## Global Constraints

- App name: `NowThere`.
- Implementation: native macOS SwiftUI app.
- Target environment: the current development machine, macOS 26.4.1 with Xcode 26.5.
- Primary API: SwiftUI `MenuBarExtra`.
- The app should not show a Dock icon.
- Show one selected time zone only.
- Menu bar title uses compact English short format.
- Menu bar title updates at launch and then once per minute.
- Default time zone is `TimeZone.current.identifier`.
- Time zone selection uses the full system time zone list from `TimeZone.knownTimeZoneIdentifiers`.
- Menu bar field toggles are `City/Label`, `Date`, `Weekday`, and `Time`.
- Persist selected time zone and field visibility across launches.
- Provide a `Launch at Login` toggle.
- No second-level menu bar updates.
- No custom format template in the initial version.
- No independent settings window in the initial version.
- No cross-platform implementation.

---

## File Structure

- `Package.swift`
  - Defines the Swift package, `NowThereCore` library target, `NowThere` executable target, and `NowThereCoreTests`.

- `Sources/NowThereCore/ClockFormatter.swift`
  - Defines `FieldVisibility`, `ClockDetails`, and `ClockFormatter`.
  - Owns all date/time formatting and menu bar title composition.

- `Sources/NowThereCore/TimeZoneStore.swift`
  - Defines `TimeZoneStore` and internal storage keys.
  - Owns `UserDefaults` persistence and invalid saved time zone recovery.

- `Sources/NowThereCore/TimeZoneSearch.swift`
  - Defines `TimeZoneSearchResult` and `TimeZoneSearch`.
  - Owns filtering system time zones by city label or IANA identifier.

- `Sources/NowThereCore/ClockViewModel.swift`
  - Defines `ClockField`, `LoginItemManaging`, and `ClockViewModel`.
  - Owns app state, timer refresh, user actions, and launch-at-login error state.

- `Sources/NowThere/NowThereApp.swift`
  - SwiftUI app entry point and `MenuBarExtra` mounting.

- `Sources/NowThere/MenuBarContentView.swift`
  - SwiftUI menu contents: details, search, field toggles, launch-at-login toggle, and quit button.

- `Sources/NowThere/SystemLoginItemManager.swift`
  - Concrete ServiceManagement adapter for `LoginItemManaging`.

- `Resources/Info.plist`
  - App bundle metadata with `LSUIElement` enabled.

- `scripts/build-app-bundle.sh`
  - Builds the Swift executable and creates `.build/<configuration>/NowThere.app`.

- `Tests/NowThereCoreTests/ClockFormatterTests.swift`
  - Unit tests for formatting and title composition.

- `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
  - Unit tests for persisted preferences and fallback behavior.

- `Tests/NowThereCoreTests/TimeZoneSearchTests.swift`
  - Unit tests for search behavior.

- `Tests/NowThereCoreTests/ClockViewModelTests.swift`
  - Unit tests for app state transitions and launch-at-login failure handling.

---

### Task 1: Clock Formatting Core

**Files:**
- Create: `Package.swift`
- Create: `Sources/NowThereCore/ClockFormatter.swift`
- Create: `Tests/NowThereCoreTests/ClockFormatterTests.swift`

**Interfaces:**
- Produces:
  - `public struct FieldVisibility: Equatable`
  - `public static let FieldVisibility.allVisible: FieldVisibility`
  - `public var FieldVisibility.hasVisibleField: Bool`
  - `public struct ClockDetails: Equatable`
  - `public final class ClockFormatter`
  - `public func ClockFormatter.title(for date: Date, timeZone: TimeZone, visibility: FieldVisibility) -> String`
  - `public func ClockFormatter.details(for date: Date, timeZone: TimeZone) -> ClockDetails`
  - `public func ClockFormatter.cityLabel(for timeZone: TimeZone) -> String`

- [ ] **Step 1: Write the failing tests and minimal package scaffold**

Create `Package.swift`:

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NowThere",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "NowThereCore", targets: ["NowThereCore"])
    ],
    targets: [
        .target(name: "NowThereCore"),
        .testTarget(name: "NowThereCoreTests", dependencies: ["NowThereCore"])
    ]
)
```

Create `Sources/NowThereCore/ClockFormatter.swift`:

```swift
import Foundation
```

Create `Tests/NowThereCoreTests/ClockFormatterTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --filter ClockFormatterTests`

Expected: FAIL with compiler errors containing `cannot find 'ClockFormatter' in scope` and `cannot find 'FieldVisibility' in scope`.

- [ ] **Step 3: Implement formatting**

Replace `Sources/NowThereCore/ClockFormatter.swift` with:

```swift
import Foundation

public struct FieldVisibility: Equatable {
    public var showsCity: Bool
    public var showsDate: Bool
    public var showsWeekday: Bool
    public var showsTime: Bool

    public init(showsCity: Bool, showsDate: Bool, showsWeekday: Bool, showsTime: Bool) {
        self.showsCity = showsCity
        self.showsDate = showsDate
        self.showsWeekday = showsWeekday
        self.showsTime = showsTime
    }

    public static let allVisible = FieldVisibility(
        showsCity: true,
        showsDate: true,
        showsWeekday: true,
        showsTime: true
    )

    public var hasVisibleField: Bool {
        showsCity || showsDate || showsWeekday || showsTime
    }
}

public struct ClockDetails: Equatable {
    public let label: String
    public let identifier: String
    public let fullDate: String
    public let fullWeekday: String
    public let time: String
    public let utcOffset: String

    public init(
        label: String,
        identifier: String,
        fullDate: String,
        fullWeekday: String,
        time: String,
        utcOffset: String
    ) {
        self.label = label
        self.identifier = identifier
        self.fullDate = fullDate
        self.fullWeekday = fullWeekday
        self.time = time
        self.utcOffset = utcOffset
    }
}

public final class ClockFormatter {
    private let locale: Locale
    private let calendarIdentifier: Calendar.Identifier

    public init(
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        calendarIdentifier: Calendar.Identifier = .gregorian
    ) {
        self.locale = locale
        self.calendarIdentifier = calendarIdentifier
    }

    public func title(
        for date: Date,
        timeZone: TimeZone,
        visibility: FieldVisibility
    ) -> String {
        guard visibility.hasVisibleField else {
            return "NowThere"
        }

        var parts: [String] = []

        if visibility.showsCity {
            parts.append(cityLabel(for: timeZone))
        }

        if visibility.showsDate {
            parts.append(format(date, format: "MMM dd", timeZone: timeZone))
        }

        if visibility.showsWeekday {
            parts.append(format(date, format: "EEE", timeZone: timeZone))
        }

        if visibility.showsTime {
            parts.append(format(date, format: "HH:mm", timeZone: timeZone))
        }

        return parts.joined(separator: " ")
    }

    public func details(for date: Date, timeZone: TimeZone) -> ClockDetails {
        ClockDetails(
            label: cityLabel(for: timeZone),
            identifier: timeZone.identifier,
            fullDate: format(date, format: "MMMM d, yyyy", timeZone: timeZone),
            fullWeekday: format(date, format: "EEEE", timeZone: timeZone),
            time: format(date, format: "HH:mm", timeZone: timeZone),
            utcOffset: utcOffset(for: date, timeZone: timeZone)
        )
    }

    public func cityLabel(for timeZone: TimeZone) -> String {
        let rawLabel = timeZone.identifier.split(separator: "/").last.map(String.init) ?? timeZone.identifier
        return rawLabel.replacingOccurrences(of: "_", with: " ")
    }

    private func format(_ date: Date, format: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: calendarIdentifier)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private func utcOffset(for date: Date, timeZone: TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3_600
        let minutes = (absoluteSeconds % 3_600) / 60
        return String(format: "UTC%@%02d:%02d", sign, hours, minutes)
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `swift test --filter ClockFormatterTests`

Expected: PASS with `Executed 4 tests`.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/NowThereCore/ClockFormatter.swift Tests/NowThereCoreTests/ClockFormatterTests.swift
git commit -m "feat: add clock formatting core" -m "AI-Co-Authored-By: Codex"
```

---

### Task 2: Preference Storage

**Files:**
- Create: `Sources/NowThereCore/TimeZoneStore.swift`
- Create: `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`

**Interfaces:**
- Consumes:
  - `FieldVisibility`
- Produces:
  - `public final class TimeZoneStore`
  - `public init(defaults: UserDefaults = .standard, fallbackTimeZone: @escaping () -> TimeZone = { .current })`
  - `public func loadTimeZone() -> TimeZone`
  - `public func saveTimeZone(_ timeZone: TimeZone)`
  - `public func loadVisibility() -> FieldVisibility`
  - `public func saveVisibility(_ visibility: FieldVisibility)`

- [ ] **Step 1: Write the failing tests**

Create `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`:

```swift
import XCTest
@testable import NowThereCore

final class TimeZoneStoreTests: XCTestCase {
    func testLoadTimeZoneUsesFallbackWhenNoValueIsSaved() throws {
        let defaults = makeDefaults()
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { tokyo })

        let loaded = store.loadTimeZone()

        XCTAssertEqual(loaded.identifier, "Asia/Tokyo")
    }

    func testLoadTimeZoneRewritesInvalidSavedIdentifierToFallback() throws {
        let defaults = makeDefaults()
        defaults.set("Mars/Olympus", forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier)
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { utc })

        let loaded = store.loadTimeZone()

        XCTAssertEqual(loaded.identifier, "UTC")
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier), "UTC")
    }

    func testSaveTimeZonePersistsIdentifier() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let newYork = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        store.saveTimeZone(newYork)

        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier), "America/New_York")
    }

    func testLoadVisibilityDefaultsEveryFieldToVisible() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        let visibility = store.loadVisibility()

        XCTAssertEqual(visibility, .allVisible)
    }

    func testSaveVisibilityPersistsFieldSwitches() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let saved = FieldVisibility(
            showsCity: false,
            showsDate: true,
            showsWeekday: false,
            showsTime: true
        )

        store.saveVisibility(saved)
        let loaded = store.loadVisibility()

        XCTAssertEqual(loaded, saved)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowThereTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --filter TimeZoneStoreTests`

Expected: FAIL with compiler errors containing `cannot find 'TimeZoneStore' in scope` and `cannot find 'TimeZoneStoreKeys' in scope`.

- [ ] **Step 3: Implement storage**

Create `Sources/NowThereCore/TimeZoneStore.swift`:

```swift
import Foundation

enum TimeZoneStoreKeys {
    static let selectedTimeZoneIdentifier = "selectedTimeZoneIdentifier"
    static let showsCity = "fieldVisibility.showsCity"
    static let showsDate = "fieldVisibility.showsDate"
    static let showsWeekday = "fieldVisibility.showsWeekday"
    static let showsTime = "fieldVisibility.showsTime"
}

public final class TimeZoneStore {
    private let defaults: UserDefaults
    private let fallbackTimeZone: () -> TimeZone

    public init(
        defaults: UserDefaults = .standard,
        fallbackTimeZone: @escaping () -> TimeZone = { .current }
    ) {
        self.defaults = defaults
        self.fallbackTimeZone = fallbackTimeZone
    }

    public func loadTimeZone() -> TimeZone {
        guard let savedIdentifier = defaults.string(forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier) else {
            return fallbackTimeZone()
        }

        guard let savedTimeZone = TimeZone(identifier: savedIdentifier) else {
            let fallback = fallbackTimeZone()
            saveTimeZone(fallback)
            return fallback
        }

        return savedTimeZone
    }

    public func saveTimeZone(_ timeZone: TimeZone) {
        defaults.set(timeZone.identifier, forKey: TimeZoneStoreKeys.selectedTimeZoneIdentifier)
    }

    public func loadVisibility() -> FieldVisibility {
        FieldVisibility(
            showsCity: bool(forKey: TimeZoneStoreKeys.showsCity, defaultValue: true),
            showsDate: bool(forKey: TimeZoneStoreKeys.showsDate, defaultValue: true),
            showsWeekday: bool(forKey: TimeZoneStoreKeys.showsWeekday, defaultValue: true),
            showsTime: bool(forKey: TimeZoneStoreKeys.showsTime, defaultValue: true)
        )
    }

    public func saveVisibility(_ visibility: FieldVisibility) {
        defaults.set(visibility.showsCity, forKey: TimeZoneStoreKeys.showsCity)
        defaults.set(visibility.showsDate, forKey: TimeZoneStoreKeys.showsDate)
        defaults.set(visibility.showsWeekday, forKey: TimeZoneStoreKeys.showsWeekday)
        defaults.set(visibility.showsTime, forKey: TimeZoneStoreKeys.showsTime)
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --filter TimeZoneStoreTests`

Expected: PASS with `Executed 5 tests`.

- [ ] **Step 5: Run all current tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/NowThereCore/TimeZoneStore.swift Tests/NowThereCoreTests/TimeZoneStoreTests.swift
git commit -m "feat: persist clock preferences" -m "AI-Co-Authored-By: Codex"
```

---

### Task 3: Time Zone Search

**Files:**
- Create: `Sources/NowThereCore/TimeZoneSearch.swift`
- Create: `Tests/NowThereCoreTests/TimeZoneSearchTests.swift`

**Interfaces:**
- Consumes:
  - `ClockFormatter.cityLabel(for:)`
- Produces:
  - `public struct TimeZoneSearchResult: Identifiable, Equatable`
  - `public struct TimeZoneSearch`
  - `public init(identifiers: [String] = TimeZone.knownTimeZoneIdentifiers, formatter: ClockFormatter = ClockFormatter())`
  - `public func results(matching query: String, limit: Int = 80) -> [TimeZoneSearchResult]`

- [ ] **Step 1: Write the failing tests**

Create `Tests/NowThereCoreTests/TimeZoneSearchTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --filter TimeZoneSearchTests`

Expected: FAIL with compiler errors containing `cannot find 'TimeZoneSearch' in scope`.

- [ ] **Step 3: Implement search**

Create `Sources/NowThereCore/TimeZoneSearch.swift`:

```swift
import Foundation

public struct TimeZoneSearchResult: Identifiable, Equatable {
    public var id: String { identifier }
    public let identifier: String
    public let label: String
    public let subtitle: String

    public init(identifier: String, label: String, subtitle: String) {
        self.identifier = identifier
        self.label = label
        self.subtitle = subtitle
    }
}

public struct TimeZoneSearch {
    private let identifiers: [String]
    private let formatter: ClockFormatter

    public init(
        identifiers: [String] = TimeZone.knownTimeZoneIdentifiers,
        formatter: ClockFormatter = ClockFormatter()
    ) {
        self.identifiers = identifiers
        self.formatter = formatter
    }

    public func results(matching query: String, limit: Int = 80) -> [TimeZoneSearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let sortedIdentifiers = identifiers.sorted()

        let matchingIdentifiers = sortedIdentifiers.filter { identifier in
            guard let timeZone = TimeZone(identifier: identifier) else {
                return false
            }

            if normalizedQuery.isEmpty {
                return true
            }

            let normalizedIdentifier = identifier.lowercased()
            let normalizedLabel = formatter.cityLabel(for: timeZone).lowercased()
            return normalizedIdentifier.contains(normalizedQuery) || normalizedLabel.contains(normalizedQuery)
        }

        return matchingIdentifiers.prefix(limit).compactMap { identifier in
            guard let timeZone = TimeZone(identifier: identifier) else {
                return nil
            }

            return TimeZoneSearchResult(
                identifier: identifier,
                label: formatter.cityLabel(for: timeZone),
                subtitle: identifier.replacingOccurrences(of: "_", with: " ")
            )
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --filter TimeZoneSearchTests`

Expected: PASS with `Executed 4 tests`.

- [ ] **Step 5: Run all current tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/NowThereCore/TimeZoneSearch.swift Tests/NowThereCoreTests/TimeZoneSearchTests.swift
git commit -m "feat: add time zone search" -m "AI-Co-Authored-By: Codex"
```

---

### Task 4: Clock View Model

**Files:**
- Create: `Sources/NowThereCore/ClockViewModel.swift`
- Create: `Tests/NowThereCoreTests/ClockViewModelTests.swift`

**Interfaces:**
- Consumes:
  - `ClockFormatter`
  - `ClockDetails`
  - `FieldVisibility`
  - `TimeZoneSearch`
  - `TimeZoneStore`
- Produces:
  - `public enum ClockField`
  - `public protocol LoginItemManaging: AnyObject`
  - `@MainActor public final class ClockViewModel: ObservableObject`
  - `public init(store: TimeZoneStore = TimeZoneStore(), formatter: ClockFormatter = ClockFormatter(), search: TimeZoneSearch = TimeZoneSearch(), loginItemManager: LoginItemManaging, nowProvider: @escaping () -> Date = Date.init, startsTimer: Bool = true)`
  - `public var selectedTimeZone: TimeZone { get }`
  - `public var now: Date { get }`
  - `public var visibility: FieldVisibility { get }`
  - `public var menuTitle: String { get }`
  - `public var details: ClockDetails { get }`
  - `public var isLaunchAtLoginEnabled: Bool { get }`
  - `public var launchAtLoginErrorMessage: String? { get }`
  - `public func refresh()`
  - `public func selectTimeZone(identifier: String)`
  - `public func setField(_ field: ClockField, isVisible: Bool)`
  - `public func searchResults(matching query: String) -> [TimeZoneSearchResult]`
  - `public func setLaunchAtLogin(_ enabled: Bool)`

- [ ] **Step 1: Write the failing tests**

Create `Tests/NowThereCoreTests/ClockViewModelTests.swift`:

```swift
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

        XCTAssertEqual(viewModel.selectedTimeZone.identifier, "UTC")
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `swift test --filter ClockViewModelTests`

Expected: FAIL with compiler errors containing `cannot find 'ClockViewModel' in scope`, `cannot find 'ClockField' in scope`, and `cannot find type 'LoginItemManaging' in scope`.

- [ ] **Step 3: Implement the view model**

Create `Sources/NowThereCore/ClockViewModel.swift`:

```swift
import Combine
import Foundation

public enum ClockField {
    case city
    case date
    case weekday
    case time
}

public protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
public final class ClockViewModel: ObservableObject {
    @Published public private(set) var selectedTimeZone: TimeZone
    @Published public private(set) var now: Date
    @Published public private(set) var visibility: FieldVisibility
    @Published public private(set) var menuTitle: String
    @Published public private(set) var isLaunchAtLoginEnabled: Bool
    @Published public private(set) var launchAtLoginErrorMessage: String?

    private let store: TimeZoneStore
    private let formatter: ClockFormatter
    private let search: TimeZoneSearch
    private let loginItemManager: LoginItemManaging
    private let nowProvider: () -> Date
    private var timer: Timer?

    public init(
        store: TimeZoneStore = TimeZoneStore(),
        formatter: ClockFormatter = ClockFormatter(),
        search: TimeZoneSearch = TimeZoneSearch(),
        loginItemManager: LoginItemManaging,
        nowProvider: @escaping () -> Date = Date.init,
        startsTimer: Bool = true
    ) {
        self.store = store
        self.formatter = formatter
        self.search = search
        self.loginItemManager = loginItemManager
        self.nowProvider = nowProvider

        let loadedTimeZone = store.loadTimeZone()
        let loadedVisibility = store.loadVisibility()
        let initialDate = nowProvider()

        self.selectedTimeZone = loadedTimeZone
        self.visibility = loadedVisibility
        self.now = initialDate
        self.menuTitle = formatter.title(
            for: initialDate,
            timeZone: loadedTimeZone,
            visibility: loadedVisibility
        )
        self.isLaunchAtLoginEnabled = loginItemManager.isEnabled
        self.launchAtLoginErrorMessage = nil

        if startsTimer {
            startTimer()
        }
    }

    public var details: ClockDetails {
        formatter.details(for: now, timeZone: selectedTimeZone)
    }

    public func refresh() {
        now = nowProvider()
        menuTitle = formatter.title(
            for: now,
            timeZone: selectedTimeZone,
            visibility: visibility
        )
    }

    public func selectTimeZone(identifier: String) {
        guard let timeZone = TimeZone(identifier: identifier) else {
            return
        }

        selectedTimeZone = timeZone
        store.saveTimeZone(timeZone)
        refresh()
    }

    public func setField(_ field: ClockField, isVisible: Bool) {
        var nextVisibility = visibility

        switch field {
        case .city:
            nextVisibility.showsCity = isVisible
        case .date:
            nextVisibility.showsDate = isVisible
        case .weekday:
            nextVisibility.showsWeekday = isVisible
        case .time:
            nextVisibility.showsTime = isVisible
        }

        visibility = nextVisibility
        store.saveVisibility(nextVisibility)
        refresh()
    }

    public func searchResults(matching query: String) -> [TimeZoneSearchResult] {
        search.results(matching: query)
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginErrorMessage = nil
        } catch {
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginErrorMessage = "Could not update launch setting"
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --filter ClockViewModelTests`

Expected: PASS with `Executed 6 tests`.

- [ ] **Step 5: Run all current tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/NowThereCore/ClockViewModel.swift Tests/NowThereCoreTests/ClockViewModelTests.swift
git commit -m "feat: add clock view model" -m "AI-Co-Authored-By: Codex"
```

---

### Task 5: SwiftUI Menu Bar App

**Files:**
- Modify: `Package.swift`
- Create: `Sources/NowThere/NowThereApp.swift`
- Create: `Sources/NowThere/MenuBarContentView.swift`
- Create: `Sources/NowThere/SystemLoginItemManager.swift`

**Interfaces:**
- Consumes:
  - `ClockViewModel`
  - `ClockDetails`
  - `ClockField`
  - `FieldVisibility`
  - `LoginItemManaging`
  - `TimeZoneSearchResult`
- Produces:
  - `@main struct NowThereApp: App`
  - `struct MenuBarContentView: View`
  - `final class SystemLoginItemManager: LoginItemManaging`

- [ ] **Step 1: Modify the package and add app source**

Replace `Package.swift` with:

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NowThere",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "NowThereCore", targets: ["NowThereCore"]),
        .executable(name: "NowThere", targets: ["NowThere"])
    ],
    targets: [
        .target(name: "NowThereCore"),
        .executableTarget(
            name: "NowThere",
            dependencies: ["NowThereCore"]
        ),
        .testTarget(name: "NowThereCoreTests", dependencies: ["NowThereCore"])
    ]
)
```

Create `Sources/NowThere/SystemLoginItemManager.swift`:

```swift
import NowThereCore
import ServiceManagement

final class SystemLoginItemManager: LoginItemManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

Create `Sources/NowThere/NowThereApp.swift`:

```swift
import NowThereCore
import SwiftUI

@main
struct NowThereApp: App {
    @StateObject private var viewModel: ClockViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue: ClockViewModel(loginItemManager: SystemLoginItemManager())
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
        } label: {
            Label {
                Text(viewModel.menuTitle)
            } icon: {
                Image(systemName: "clock")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
```

Create `Sources/NowThere/MenuBarContentView.swift`:

```swift
import AppKit
import NowThereCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailsSection

            Divider()

            timeZoneSearchSection

            Divider()

            settingsSection

            Divider()

            Button("Quit NowThere") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private var detailsSection: some View {
        let details = viewModel.details

        return VStack(alignment: .leading, spacing: 6) {
            Text(details.label)
                .font(.headline)

            detailRow(label: "Time Zone", value: details.identifier)
            detailRow(label: "Date", value: details.fullDate)
            detailRow(label: "Weekday", value: details.fullWeekday)
            detailRow(label: "Time", value: details.time)
            detailRow(label: "UTC Offset", value: details.utcOffset)
        }
    }

    private var timeZoneSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Zone")
                .font(.headline)

            TextField("Search city or time zone", text: $searchText)
                .textFieldStyle(.roundedBorder)

            let results = viewModel.searchResults(matching: searchText)

            if results.isEmpty {
                Text("No matching time zones")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(results) { result in
                            Button {
                                viewModel.selectTimeZone(identifier: result.identifier)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.label)
                                            .font(.body)
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if result.identifier == viewModel.selectedTimeZone.identifier {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accent)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu Bar Fields")
                .font(.headline)

            Toggle("City/Label", isOn: fieldBinding(.city))
            Toggle("Date", isOn: fieldBinding(.date))
            Toggle("Weekday", isOn: fieldBinding(.weekday))
            Toggle("Time", isOn: fieldBinding(.time))

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            ))

            if let message = viewModel.launchAtLoginErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func fieldBinding(_ field: ClockField) -> Binding<Bool> {
        Binding(
            get: {
                switch field {
                case .city:
                    viewModel.visibility.showsCity
                case .date:
                    viewModel.visibility.showsDate
                case .weekday:
                    viewModel.visibility.showsWeekday
                case .time:
                    viewModel.visibility.showsTime
                }
            },
            set: { isVisible in
                viewModel.setField(field, isVisible: isVisible)
            }
        )
    }
}
```

- [ ] **Step 2: Build the app target**

Run: `swift build --product NowThere`

Expected: PASS and output includes `Build complete!`.

- [ ] **Step 3: Run all tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources/NowThere/NowThereApp.swift Sources/NowThere/MenuBarContentView.swift Sources/NowThere/SystemLoginItemManager.swift
git commit -m "feat: add SwiftUI menu bar app" -m "AI-Co-Authored-By: Codex"
```

---

### Task 6: App Bundle Packaging

**Files:**
- Create: `Resources/Info.plist`
- Create: `scripts/build-app-bundle.sh`

**Interfaces:**
- Consumes:
  - `swift build --product NowThere`
  - `.build/<configuration>/NowThere`
- Produces:
  - `.build/<configuration>/NowThere.app`
  - `Contents/Info.plist` with `LSUIElement` set to `true`
  - `Contents/MacOS/NowThere`

- [ ] **Step 1: Create app bundle metadata and build script**

Create `Resources/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>NowThere</string>
    <key>CFBundleIdentifier</key>
    <string>com.zhangfan.NowThere</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>NowThere</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

Create `scripts/build-app-bundle.sh`:

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

echo "$APP_DIR"
```

Run: `chmod +x scripts/build-app-bundle.sh`

Expected: command exits with status 0.

- [ ] **Step 2: Build the app bundle**

Run: `scripts/build-app-bundle.sh debug`

Expected: PASS and final output is `.build/debug/NowThere.app`.

- [ ] **Step 3: Verify LSUIElement is present**

Run: `/usr/libexec/PlistBuddy -c "Print :LSUIElement" .build/debug/NowThere.app/Contents/Info.plist`

Expected: output is `true`.

- [ ] **Step 4: Run all tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Resources/Info.plist scripts/build-app-bundle.sh
git commit -m "build: add macOS app bundle packaging" -m "AI-Co-Authored-By: Codex"
```

---

### Task 7: Final Verification

**Files:**
- No source changes expected.

**Interfaces:**
- Consumes:
  - `.build/debug/NowThere.app`
- Produces:
  - Verified menu bar app behavior against the design spec.

- [ ] **Step 1: Run unit tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 2: Build the app target**

Run: `swift build --product NowThere`

Expected: PASS and output includes `Build complete!`.

- [ ] **Step 3: Build the app bundle**

Run: `scripts/build-app-bundle.sh debug`

Expected: PASS and final output is `.build/debug/NowThere.app`.

- [ ] **Step 4: Launch the app bundle for manual verification**

Run: `open .build/debug/NowThere.app`

Expected: NowThere appears in the macOS menu bar and no Dock icon appears.

- [ ] **Step 5: Complete manual acceptance checks**

Use the running menu bar app and verify:

- The menu bar shows the local time zone on first launch.
- Selecting `Asia/Tokyo` updates the menu bar title immediately.
- Restarting the app preserves the selected time zone.
- Turning off `City/Label`, `Date`, `Weekday`, and `Time` changes the menu bar title to `NowThere`.
- Turning fields back on updates the title immediately.
- Searching for `Tokyo` returns `Asia/Tokyo`.
- Searching for `NoSuchCity` shows `No matching time zones`.
- `Launch at Login` toggle updates its displayed state after the click.
- `Quit NowThere` exits the app.

- [ ] **Step 6: Check repository state**

Run: `git status --short`

Expected: no output.
