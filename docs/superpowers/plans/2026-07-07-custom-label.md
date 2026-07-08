# Custom Label Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional custom label that appears before the selected city in the NowThere menu bar title.

**Architecture:** Keep title composition in `ClockFormatter`, preference persistence in `TimeZoneStore`, app state and actions in `ClockViewModel`, and the settings control in `MenuBarContentView`. The custom label is a plain persisted string; it has no visibility toggle and is hidden when empty after trimming whitespace.

**Tech Stack:** Swift 6, SwiftUI `MenuBarExtra`, Foundation `UserDefaults`/`DateFormatter`, XCTest, Swift Package Manager.

## Global Constraints

- The custom label appears before the city.
- Empty or whitespace-only labels are hidden.
- Clearing the text field removes the label from the menu bar title.
- Existing city, date, weekday, and time visibility toggles continue to work.
- If all existing fields are hidden but the custom label is present, the menu bar title shows the label.
- If all fields are hidden and the custom label is empty, the menu bar title remains `NowThere`.
- The label has no separate visibility toggle.
- Do not add `AI-Co-Authored-By: Codex` to commit messages for this project.

---

## File Structure

- `Sources/NowThereCore/ClockFormatter.swift`
  - Add the custom label parameter to menu title composition.
  - Trim label whitespace before display.
  - Keep `FieldVisibility` focused on city, date, weekday, and time only.

- `Sources/NowThereCore/TimeZoneStore.swift`
  - Add the `customLabel` storage key.
  - Add `loadCustomLabel() -> String` and `saveCustomLabel(_:)`.

- `Sources/NowThereCore/ClockViewModel.swift`
  - Add published `customLabel`.
  - Load the label during initialization.
  - Include the label in all title refreshes.
  - Add `setCustomLabel(_:)` to update, persist, and refresh.

- `Sources/NowThere/MenuBarContentView.swift`
  - Add a `Custom Label` text field to the settings section.
  - Bind text edits to `ClockViewModel.setCustomLabel(_:)`.

- `Tests/NowThereCoreTests/ClockFormatterTests.swift`
  - Add formatter coverage for label ordering, empty label hiding, label-only fallback, and empty fallback.
  - Update existing title calls to pass `customLabel: ""`.

- `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
  - Add persistence coverage for `customLabel`.

- `Tests/NowThereCoreTests/ClockViewModelTests.swift`
  - Add view model coverage for loading, setting, persisting, and refreshing the custom label.
  - Update existing title expectations only where needed.

- `Tests/NowThereAppTests/MenuBarTitleTests.swift`
  - Add app-level coverage that the menu bar label sees the custom label through `ClockViewModel.menuTitle`.

---

### Task 1: Formatter Custom Label

**Files:**
- Modify: `Sources/NowThereCore/ClockFormatter.swift`
- Modify: `Tests/NowThereCoreTests/ClockFormatterTests.swift`

**Interfaces:**
- Consumes: `FieldVisibility`, `ClockFormatter.cityLabel(for:)`
- Produces: `public func ClockFormatter.title(for date: Date, timeZone: TimeZone, visibility: FieldVisibility, customLabel: String = "") -> String`

- [ ] **Step 1: Write the failing formatter tests**

In `Tests/NowThereCoreTests/ClockFormatterTests.swift`, update existing calls from:

```swift
formatter.title(for: date, timeZone: tokyo, visibility: visibility)
```

to:

```swift
formatter.title(for: date, timeZone: tokyo, visibility: visibility, customLabel: "")
```

For the `.allVisible` test, use:

```swift
formatter.title(for: date, timeZone: tokyo, visibility: .allVisible, customLabel: "")
```

Then add these tests before `testDetailsIncludeFullDateWeekdayTimeAndOffset`:

```swift
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
```

- [ ] **Step 2: Run formatter tests and verify failure**

Run:

```bash
swift test --filter ClockFormatterTests
```

Expected: compile failure because `ClockFormatter.title` does not accept `customLabel`.

If the Codex sandbox blocks SwiftPM cache or manifest work, rerun with:

```bash
HOME=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/nowthere-clang-cache SWIFT_MODULE_CACHE_PATH=/private/tmp/nowthere-swift-module-cache SWIFT_CACHE_DIR=/private/tmp/nowthere-swift-cache SWIFTPM_CACHE_PATH=/private/tmp/nowthere-swiftpm-cache SWIFT_USER_STATE_DIR=/private/tmp/nowthere-swift-user-state swift test --filter ClockFormatterTests
```

- [ ] **Step 3: Implement formatter support**

In `Sources/NowThereCore/ClockFormatter.swift`, replace the `title` method with:

```swift
public func title(
    for date: Date,
    timeZone: TimeZone,
    visibility: FieldVisibility,
    customLabel: String = ""
) -> String {
    var parts: [String] = []
    let trimmedCustomLabel = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)

    if !trimmedCustomLabel.isEmpty {
        parts.append(trimmedCustomLabel)
    }

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

    guard !parts.isEmpty else {
        return "NowThere"
    }

    return parts.joined(separator: " ")
}
```

- [ ] **Step 4: Run formatter tests and verify pass**

Run:

```bash
swift test --filter ClockFormatterTests
```

Expected: `ClockFormatterTests` pass.

- [ ] **Step 5: Commit formatter task**

Run:

```bash
git add Sources/NowThereCore/ClockFormatter.swift Tests/NowThereCoreTests/ClockFormatterTests.swift
git commit -m "feat: add custom label title formatting"
```

---

### Task 2: Persistence And View Model State

**Files:**
- Modify: `Sources/NowThereCore/TimeZoneStore.swift`
- Modify: `Sources/NowThereCore/ClockViewModel.swift`
- Modify: `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
- Modify: `Tests/NowThereCoreTests/ClockViewModelTests.swift`

**Interfaces:**
- Consumes: `ClockFormatter.title(for:timeZone:visibility:customLabel:)`
- Produces:
  - `TimeZoneStoreKeys.customLabel`
  - `public func TimeZoneStore.loadCustomLabel() -> String`
  - `public func TimeZoneStore.saveCustomLabel(_ label: String)`
  - `@Published public private(set) var customLabel: String`
  - `public func ClockViewModel.setCustomLabel(_ label: String)`

- [ ] **Step 1: Write failing store tests**

In `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`, add:

```swift
func testLoadCustomLabelDefaultsToEmptyString() {
    let defaults = makeDefaults()
    let store = TimeZoneStore(defaults: defaults)

    XCTAssertEqual(store.loadCustomLabel(), "")
}

func testSaveCustomLabelPersistsValue() {
    let defaults = makeDefaults()
    let store = TimeZoneStore(defaults: defaults)

    store.saveCustomLabel("Work")

    XCTAssertEqual(store.loadCustomLabel(), "Work")
    XCTAssertEqual(defaults.string(forKey: TimeZoneStoreKeys.customLabel), "Work")
}
```

- [ ] **Step 2: Write failing view model tests**

In `Tests/NowThereCoreTests/ClockViewModelTests.swift`, update existing expected title strings only if the test setup saves a custom label.

In `testInitialStateUsesStoredPreferencesAndBuildsTitle`, after `store.saveVisibility(...)`, add:

```swift
store.saveCustomLabel("Work")
```

Then update the assertions:

```swift
XCTAssertEqual(viewModel.customLabel, "Work")
XCTAssertEqual(viewModel.menuTitle, "Work Tokyo 12:34")
```

Add this new test after `testSelectingTimeZonePersistsAndRefreshesTitle`:

```swift
func testSettingCustomLabelPersistsAndRefreshesTitle() throws {
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

    viewModel.setCustomLabel("Work")

    XCTAssertEqual(viewModel.customLabel, "Work")
    XCTAssertEqual(viewModel.menuTitle, "Work UTC Jul 08 Wed 03:34")
    XCTAssertEqual(store.loadCustomLabel(), "Work")
}
```

Add this new test after `testFieldTogglePersistsAndFallsBackToAppNameWhenAllFieldsAreHidden`:

```swift
func testCustomLabelIsShownWhenAllFieldsAreHidden() throws {
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

    viewModel.setCustomLabel("Work")
    viewModel.setField(.city, isVisible: false)
    viewModel.setField(.date, isVisible: false)
    viewModel.setField(.weekday, isVisible: false)
    viewModel.setField(.time, isVisible: false)

    XCTAssertEqual(viewModel.menuTitle, "Work")
}
```

- [ ] **Step 3: Run store and view model tests and verify failure**

Run:

```bash
swift test --filter TimeZoneStoreTests
swift test --filter ClockViewModelTests
```

Expected: compile failure because `loadCustomLabel`, `saveCustomLabel`, `customLabel`, and `setCustomLabel` do not exist yet.

- [ ] **Step 4: Implement store persistence**

In `Sources/NowThereCore/TimeZoneStore.swift`, add the key:

```swift
static let customLabel = "customLabel"
```

Add these methods inside `TimeZoneStore`:

```swift
public func loadCustomLabel() -> String {
    defaults.string(forKey: TimeZoneStoreKeys.customLabel) ?? ""
}

public func saveCustomLabel(_ label: String) {
    defaults.set(label, forKey: TimeZoneStoreKeys.customLabel)
}
```

- [ ] **Step 5: Implement view model state**

In `Sources/NowThereCore/ClockViewModel.swift`, add the published property near `visibility`:

```swift
@Published public private(set) var customLabel: String
```

In the initializer, load the value:

```swift
let loadedCustomLabel = store.loadCustomLabel()
```

Set the property:

```swift
self.customLabel = loadedCustomLabel
```

Update the initial title call:

```swift
self.menuTitle = formatter.title(
    for: initialDate,
    timeZone: loadedTimeZone,
    visibility: loadedVisibility,
    customLabel: loadedCustomLabel
)
```

Update `refresh()`:

```swift
public func refresh() {
    now = nowProvider()
    menuTitle = formatter.title(
        for: now,
        timeZone: selectedTimeZone,
        visibility: visibility,
        customLabel: customLabel
    )
}
```

Add the setter before `setField`:

```swift
public func setCustomLabel(_ label: String) {
    customLabel = label
    store.saveCustomLabel(label)
    refresh()
}
```

- [ ] **Step 6: Run store and view model tests and verify pass**

Run:

```bash
swift test --filter TimeZoneStoreTests
swift test --filter ClockViewModelTests
```

Expected: both test suites pass.

- [ ] **Step 7: Commit persistence and view model task**

Run:

```bash
git add Sources/NowThereCore/TimeZoneStore.swift Sources/NowThereCore/ClockViewModel.swift Tests/NowThereCoreTests/TimeZoneStoreTests.swift Tests/NowThereCoreTests/ClockViewModelTests.swift
git commit -m "feat: persist custom clock label"
```

---

### Task 3: Menu UI And App-Level Verification

**Files:**
- Modify: `Sources/NowThere/MenuBarContentView.swift`
- Modify: `Tests/NowThereAppTests/MenuBarTitleTests.swift`

**Interfaces:**
- Consumes:
  - `ClockViewModel.customLabel`
  - `ClockViewModel.setCustomLabel(_:)`
  - `NowThereMenuBarLabel.title(for:)`
- Produces: a visible `Custom Label` text field in the settings panel.

- [ ] **Step 1: Add app-level regression test**

In `Tests/NowThereAppTests/MenuBarTitleTests.swift`, add this test after `testMenuBarLabelUsesVisibleClockTitleText`:

```swift
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
```

- [ ] **Step 2: Run app tests**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: pass if Task 2 is complete, because `NowThereMenuBarLabel` already reads `viewModel.menuTitle`.

- [ ] **Step 3: Add the settings text field**

In `Sources/NowThere/MenuBarContentView.swift`, add this block in `settingsSection`, after the `Text("Menu Bar Fields").font(.headline)` heading and before the toggles:

```swift
HStack {
    Text("Custom Label")
    Spacer()
    TextField(
        "Work, Home, Client",
        text: Binding(
            get: { viewModel.customLabel },
            set: { viewModel.setCustomLabel($0) }
        )
    )
    .textFieldStyle(.roundedBorder)
    .frame(width: 190)
}
```

- [ ] **Step 4: Run app tests and full test suite**

Run:

```bash
swift test --filter MenuBarTitleTests
swift test
```

Expected: all tests pass.

- [ ] **Step 5: Build the app bundle**

Run:

```bash
scripts/build-app-bundle.sh debug
```

Expected: `.build/debug/NowThere.app` is created.

- [ ] **Step 6: Commit UI task**

Run:

```bash
git add Sources/NowThere/MenuBarContentView.swift Tests/NowThereAppTests/MenuBarTitleTests.swift
git commit -m "feat: add custom label setting"
```

---

### Task 4: Final Verification And Push

**Files:**
- No source changes expected.

**Interfaces:**
- Consumes: all tasks above.
- Produces: verified feature branch state on `main`.

- [ ] **Step 1: Run final tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 2: Build app bundle**

Run:

```bash
scripts/build-app-bundle.sh debug
```

Expected: `.build/debug/NowThere.app` exists.

- [ ] **Step 3: Inspect git history**

Run:

```bash
git log --oneline -6
```

Expected: recent commits include the custom label design, this plan, and implementation commits. None of the custom label commits contain `AI-Co-Authored-By: Codex`.

- [ ] **Step 4: Push to origin**

Run:

```bash
git push origin main
```

Expected: `main` pushes successfully to `git@github.com:alex0811/NowThere.git`.
