# Title Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted `Title Style` setting so NowThere can keep the current menu bar title or make the time easier to scan with time-forward text formats.

**Architecture:** Add a small `TitleStyle` value type to `NowThereCore`, teach `ClockFormatter` to arrange already-formatted field parts by style, persist the selected style in `TimeZoneStore`, and bind it through `ClockViewModel` into a SwiftUI picker in the existing menu. The feature stays text-only and reuses the current menu bar title pipeline.

**Tech Stack:** Swift 6, SwiftUI `MenuBarExtra`, Foundation `DateFormatter` and `UserDefaults`, XCTest, Swift Package Manager.

## Global Constraints

- Platform target remains macOS 13+.
- Preserve the current default output: `Tokyo Jul 08 Wed 12:34`.
- Supported styles are `Default`, `Time First`, `Separated`, and `Bracketed`.
- No rich text, partial background, or true bordered capsule inside the menu bar title.
- No custom free-form format template.
- No new settings window.
- No change to the detailed menu content.
- Existing `City/Label`, `Date`, `Weekday`, and `Time` toggles continue to decide which fields are available for the title.
- If `Time` is hidden, time-focused styles fall back to the non-time fields in default order.
- If every clock field is hidden and there is no custom label, the title remains `NowThere`.
- If every clock field is hidden but a custom label exists, the title remains that custom label.

---

## File Structure

- `Sources/NowThereCore/TitleStyle.swift`
  - New core enum for the persisted title style and menu display labels.
  - Kept separate from `ClockFormatter.swift` so UI and storage can use the style without depending on formatter internals.

- `Sources/NowThereCore/ClockFormatter.swift`
  - Continues to own date/time string formatting.
  - Adds a `titleStyle` parameter to `title(...)` with `.standard` default, preserving existing callers.
  - Applies style only after visible field strings are built.

- `Sources/NowThereCore/TimeZoneStore.swift`
  - Adds `titleStyle` storage key.
  - Adds `loadTitleStyle()` and `saveTitleStyle(_:)`.
  - Rewrites invalid saved style values to the default style.

- `Sources/NowThereCore/ClockViewModel.swift`
  - Adds published `titleStyle`.
  - Loads the stored style at startup.
  - Refreshes and persists the menu title when style changes.

- `Sources/NowThere/MenuBarContentView.swift`
  - Adds a `Title Style` picker to the existing `Menu Bar Fields` section.
  - Binds picker selection to `ClockViewModel.setTitleStyle(_:)`.

- `Tests/NowThereCoreTests/ClockFormatterTests.swift`
  - Covers all style outputs, hidden-time fallback, and custom label behavior.

- `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
  - Covers title style default, save/load, and invalid stored value rewrite.

- `Tests/NowThereCoreTests/ClockViewModelTests.swift`
  - Covers initial load from store and runtime style changes.

---

### Task 1: Core Title Style Formatting

**Files:**
- Create: `Sources/NowThereCore/TitleStyle.swift`
- Modify: `Sources/NowThereCore/ClockFormatter.swift`
- Test: `Tests/NowThereCoreTests/ClockFormatterTests.swift`

**Interfaces:**
- Consumes: Existing `FieldVisibility`, `ClockFormatter.title(for:timeZone:visibility:customLabel:)`, and date formatting behavior.
- Produces:
  - `public enum TitleStyle: String, CaseIterable, Identifiable, Equatable, Sendable`
  - `public var TitleStyle.id: String`
  - `public var TitleStyle.displayName: String`
  - `ClockFormatter.title(for: Date, timeZone: TimeZone, visibility: FieldVisibility, customLabel: String, titleStyle: TitleStyle) -> String`

- [ ] **Step 1: Write failing formatter tests**

Add these tests to `Tests/NowThereCoreTests/ClockFormatterTests.swift` after `testTitleTrimsAndHidesWhitespaceOnlyCustomLabel()`:

```swift
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
```

- [ ] **Step 2: Run formatter tests and verify failure**

Run:

```bash
swift test --filter ClockFormatterTests
```

Expected: FAIL. The compiler should report that `titleStyle` or the style cases are not available yet.

- [ ] **Step 3: Add `TitleStyle`**

Create `Sources/NowThereCore/TitleStyle.swift`:

```swift
import Foundation

public enum TitleStyle: String, CaseIterable, Identifiable, Equatable, Sendable {
    case standard = "default"
    case timeFirst
    case separated
    case bracketed

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .standard:
            "Default"
        case .timeFirst:
            "Time First"
        case .separated:
            "Separated"
        case .bracketed:
            "Bracketed"
        }
    }
}
```

- [ ] **Step 4: Update formatter title construction**

Replace the current `title(for:timeZone:visibility:customLabel:)` method in `Sources/NowThereCore/ClockFormatter.swift` with this method and add the helper below it:

```swift
    public func title(
        for date: Date,
        timeZone: TimeZone,
        visibility: FieldVisibility,
        customLabel: String = "",
        titleStyle: TitleStyle = .standard
    ) -> String {
        var nonTimeParts: [String] = []
        let trimmedCustomLabel = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedCustomLabel.isEmpty {
            nonTimeParts.append(trimmedCustomLabel)
        }

        if visibility.showsCity {
            nonTimeParts.append(cityLabel(for: timeZone))
        }

        if visibility.showsDate {
            nonTimeParts.append(format(date, format: "MMM dd", timeZone: timeZone))
        }

        if visibility.showsWeekday {
            nonTimeParts.append(format(date, format: "EEE", timeZone: timeZone))
        }

        let timePart = visibility.showsTime ? format(date, format: "HH:mm", timeZone: timeZone) : nil

        switch titleStyle {
        case .standard:
            var parts = nonTimeParts

            if let timePart {
                parts.append(timePart)
            }

            return title(from: parts)
        case .timeFirst:
            guard let timePart else {
                return title(from: nonTimeParts)
            }

            return title(from: [timePart] + nonTimeParts)
        case .separated:
            guard let timePart else {
                return title(from: nonTimeParts)
            }

            let details = nonTimeParts.joined(separator: " ")
            return details.isEmpty ? timePart : "\(timePart) | \(details)"
        case .bracketed:
            guard let timePart else {
                return title(from: nonTimeParts)
            }

            return title(from: ["[\(timePart)]"] + nonTimeParts)
        }
    }

    private func title(from parts: [String]) -> String {
        guard !parts.isEmpty else {
            return "NowThere"
        }

        return parts.joined(separator: " ")
    }
```

- [ ] **Step 5: Run formatter tests and verify pass**

Run:

```bash
swift test --filter ClockFormatterTests
```

Expected: PASS. Existing default-style tests should still pass because `titleStyle` defaults to `.standard`.

- [ ] **Step 6: Commit formatter support**

Run:

```bash
git add Sources/NowThereCore/TitleStyle.swift Sources/NowThereCore/ClockFormatter.swift Tests/NowThereCoreTests/ClockFormatterTests.swift
git commit -m "feat: add title style formatting" -m "AI-Co-Authored-By: Codex"
```

---

### Task 2: Persist Title Style

**Files:**
- Modify: `Sources/NowThereCore/TimeZoneStore.swift`
- Test: `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`

**Interfaces:**
- Consumes:
  - `TitleStyle.standard`, `.timeFirst`, `.separated`, `.bracketed`
  - `TitleStyle(rawValue:)`
- Produces:
  - `TimeZoneStoreKeys.titleStyle`
  - `public func TimeZoneStore.loadTitleStyle() -> TitleStyle`
  - `public func TimeZoneStore.saveTitleStyle(_ titleStyle: TitleStyle)`

- [ ] **Step 1: Write failing store tests**

Add these tests to `Tests/NowThereCoreTests/TimeZoneStoreTests.swift` after `testSaveCustomLabelPersistsValue()`:

```swift
    func testLoadTitleStyleDefaultsToStandard() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        XCTAssertEqual(store.loadTitleStyle(), .standard)
    }

    func testSaveTitleStylePersistsValue() {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)

        store.saveTitleStyle(.separated)

        XCTAssertEqual(store.loadTitleStyle(), .separated)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.titleStyle), "separated")
    }

    func testLoadTitleStyleRewritesInvalidSavedValueToStandard() {
        let defaults = makeDefaults()
        defaults.set("outline", forKey: TimeZoneStoreKeys.titleStyle)
        let store = TimeZoneStore(defaults: defaults)

        let loaded = store.loadTitleStyle()

        XCTAssertEqual(loaded, .standard)
        XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.titleStyle), TitleStyle.standard.rawValue)
    }
```

- [ ] **Step 2: Run store tests and verify failure**

Run:

```bash
swift test --filter TimeZoneStoreTests
```

Expected: FAIL. The compiler should report missing `loadTitleStyle`, `saveTitleStyle`, or `TimeZoneStoreKeys.titleStyle`.

- [ ] **Step 3: Add storage key and load/save methods**

In `Sources/NowThereCore/TimeZoneStore.swift`, add this key to `TimeZoneStoreKeys`:

```swift
    static let titleStyle = "titleStyle"
```

Add these methods to `TimeZoneStore` after `saveCustomLabel(_:)`:

```swift
    public func loadTitleStyle() -> TitleStyle {
        guard let savedValue = defaults.string(forKey: TimeZoneStoreKeys.titleStyle) else {
            return .standard
        }

        guard let titleStyle = TitleStyle(rawValue: savedValue) else {
            saveTitleStyle(.standard)
            return .standard
        }

        return titleStyle
    }

    public func saveTitleStyle(_ titleStyle: TitleStyle) {
        defaults.set(titleStyle.rawValue, forKey: TimeZoneStoreKeys.titleStyle)
    }
```

- [ ] **Step 4: Run store tests and verify pass**

Run:

```bash
swift test --filter TimeZoneStoreTests
```

Expected: PASS.

- [ ] **Step 5: Commit persistence support**

Run:

```bash
git add Sources/NowThereCore/TimeZoneStore.swift Tests/NowThereCoreTests/TimeZoneStoreTests.swift
git commit -m "feat: persist title style setting" -m "AI-Co-Authored-By: Codex"
```

---

### Task 3: Wire Title Style Into View Model And Menu

**Files:**
- Modify: `Sources/NowThereCore/ClockViewModel.swift`
- Modify: `Sources/NowThere/MenuBarContentView.swift`
- Test: `Tests/NowThereCoreTests/ClockViewModelTests.swift`

**Interfaces:**
- Consumes:
  - `TimeZoneStore.loadTitleStyle() -> TitleStyle`
  - `TimeZoneStore.saveTitleStyle(_:)`
  - `ClockFormatter.title(..., titleStyle: TitleStyle)`
  - `TitleStyle.allCases`
  - `TitleStyle.displayName`
- Produces:
  - `@Published public private(set) var ClockViewModel.titleStyle: TitleStyle`
  - `public func ClockViewModel.setTitleStyle(_ titleStyle: TitleStyle)`
  - A SwiftUI `Picker("Title Style", selection:)` in `MenuBarContentView.settingsSection`

- [ ] **Step 1: Write failing view model tests**

Add these tests to `Tests/NowThereCoreTests/ClockViewModelTests.swift` after `testSettingCustomLabelPersistsAndRefreshesTitle()`:

```swift
    func testInitialStateUsesStoredTitleStyle() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveTitleStyle(.separated)
        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)

        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(viewModel.titleStyle, .separated)
        XCTAssertEqual(viewModel.menuTitle, "12:34 | Tokyo Jul 08 Wed")
    }

    func testSettingTitleStylePersistsAndRefreshesTitle() throws {
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

        viewModel.setTitleStyle(.bracketed)

        XCTAssertEqual(viewModel.titleStyle, .bracketed)
        XCTAssertEqual(viewModel.menuTitle, "[12:34] Tokyo Jul 08 Wed")
        XCTAssertEqual(store.loadTitleStyle(), .bracketed)
    }
```

- [ ] **Step 2: Run view model tests and verify failure**

Run:

```bash
swift test --filter ClockViewModelTests
```

Expected: FAIL. The compiler should report missing `ClockViewModel.titleStyle` or `setTitleStyle(_:)`.

- [ ] **Step 3: Add `titleStyle` state to `ClockViewModel`**

In `Sources/NowThereCore/ClockViewModel.swift`, add the published property beside `customLabel`:

```swift
    @Published public private(set) var titleStyle: TitleStyle
```

In `init(...)`, load the stored style after `loadedCustomLabel`:

```swift
        let loadedTitleStyle = store.loadTitleStyle()
```

Set the property in the initializer:

```swift
        self.titleStyle = loadedTitleStyle
```

Update the initial `menuTitle` assignment to pass the style:

```swift
        self.menuTitle = formatter.title(
            for: initialDate,
            timeZone: loadedTimeZone,
            visibility: loadedVisibility,
            customLabel: loadedCustomLabel,
            titleStyle: loadedTitleStyle
        )
```

Update `refresh()` to pass the current style:

```swift
    public func refresh() {
        now = nowProvider()
        menuTitle = formatter.title(
            for: now,
            timeZone: selectedTimeZone,
            visibility: visibility,
            customLabel: customLabel,
            titleStyle: titleStyle
        )
    }
```

Add this method after `setCustomLabel(_:)`:

```swift
    public func setTitleStyle(_ titleStyle: TitleStyle) {
        self.titleStyle = titleStyle
        store.saveTitleStyle(titleStyle)
        refresh()
    }
```

- [ ] **Step 4: Add the menu picker**

In `Sources/NowThere/MenuBarContentView.swift`, add this picker in `settingsSection` after the `Custom Label` row and before the field toggles:

```swift
            Picker("Title Style", selection: Binding(
                get: { viewModel.titleStyle },
                set: { viewModel.setTitleStyle($0) }
            )) {
                ForEach(TitleStyle.allCases) { titleStyle in
                    Text(titleStyle.displayName)
                        .tag(titleStyle)
                }
            }
            .pickerStyle(.menu)
```

- [ ] **Step 5: Run all tests and verify pass**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 6: Build the app product**

Run:

```bash
swift build --product NowThere
```

Expected: Build completes without compiler errors.

- [ ] **Step 7: Commit view model and menu wiring**

Run:

```bash
git add Sources/NowThereCore/ClockViewModel.swift Sources/NowThere/MenuBarContentView.swift Tests/NowThereCoreTests/ClockViewModelTests.swift
git commit -m "feat: add title style picker" -m "AI-Co-Authored-By: Codex"
```

---

## Final Verification

- [ ] Run the focused formatter tests:

```bash
swift test --filter ClockFormatterTests
```

Expected: PASS.

- [ ] Run the focused store tests:

```bash
swift test --filter TimeZoneStoreTests
```

Expected: PASS.

- [ ] Run the focused view model tests:

```bash
swift test --filter ClockViewModelTests
```

Expected: PASS.

- [ ] Run the full test suite:

```bash
swift test
```

Expected: PASS.

- [ ] Build the executable:

```bash
swift build --product NowThere
```

Expected: PASS.

- [ ] Check the final diff only contains planned files:

```bash
git status --short
```

Expected: clean working tree after the three task commits.
