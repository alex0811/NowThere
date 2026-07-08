# Task 3: Menu UI And App-Level Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the settings-panel `Custom Label` text field and verify the menu bar title includes the persisted custom label at the app layer.

**Architecture:** Keep all title composition and persistence behavior in the core layer already completed by Tasks 1 and 2. This task only binds the existing `ClockViewModel.customLabel` and `ClockViewModel.setCustomLabel(_:)` APIs into the SwiftUI menu content and adds an app-level regression test that exercises `NowThereMenuBarLabel.title(for:)` end to end.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Swift Package Manager.

## Global Constraints

- Do not touch core formatter/store/view model implementation except if absolutely required by compile failures.
- Do not touch README, license, scripts, or unrelated files.
- Do not add `AI-Co-Authored-By: Codex` to commit messages for this project.

---

### Task 1: App-Level Regression Test

**Files:**
- Modify: `Tests/NowThereAppTests/MenuBarTitleTests.swift`

**Interfaces:**
- Consumes: `ClockViewModel.customLabel`, `ClockViewModel.setCustomLabel(_:)`, `NowThereMenuBarLabel.title(for:)`
- Produces: regression coverage for custom-label propagation into the menu bar title

- [ ] **Step 1: Add the failing app-level test**

Add this test after `testMenuBarLabelUsesVisibleClockTitleText`:

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

- [ ] **Step 2: Run the app tests**

Run: `swift test --filter MenuBarTitleTests`

Expected: pass, because `NowThereMenuBarLabel` already reads `viewModel.menuTitle`.

### Task 2: Settings Text Field

**Files:**
- Modify: `Sources/NowThere/MenuBarContentView.swift`

**Interfaces:**
- Consumes: `ClockViewModel.customLabel`, `ClockViewModel.setCustomLabel(_:)`
- Produces: a visible `Custom Label` text field in the settings section

- [ ] **Step 1: Add the settings text field**

Insert this block in `settingsSection`, after `Text("Menu Bar Fields").font(.headline)` and before the toggles:

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

- [ ] **Step 2: Run the app tests again**

Run: `swift test --filter MenuBarTitleTests`

Expected: pass.

- [ ] **Step 3: Run the full test suite**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 4: Build the app bundle**

Run: `scripts/build-app-bundle.sh debug`

Expected: `.build/debug/NowThere.app` is created.

- [ ] **Step 5: Commit the UI task**

Run:

```bash
git add Sources/NowThere/MenuBarContentView.swift Tests/NowThereAppTests/MenuBarTitleTests.swift
git commit -m "feat: add custom label setting"
```

