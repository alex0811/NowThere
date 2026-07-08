# Menu Bar Label Appearance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make NowThere's menu bar title visually closer to the system clock by applying system-managed primary foreground styling and a regular system font to the `MenuBarExtra` label.

**Architecture:** Keep title text generation unchanged in `NowThereMenuBarLabel.title(for:)`. Add a small SwiftUI helper on `NowThereMenuBarLabel` that builds the styled label view, and have `NowThereApp` use that helper from the `MenuBarExtra` label closure.

**Tech Stack:** Swift 6, SwiftUI `MenuBarExtra`, AppKit `NSFont`, XCTest, Swift Package Manager.

## Global Constraints

- Preserve automatic light/dark appearance adaptation.
- Keep the title text-only and compatible with existing title styles.
- No custom fixed text color.
- No heavier-than-system emphasis such as semibold or bold.
- No background, border, capsule, shadow, or glow.
- No replacement of `MenuBarExtra` with a custom `NSStatusItem` view in this first pass.
- No change to title formatting, title style options, or persisted preferences.

---

## File Structure

- `Sources/NowThere/NowThereApp.swift`
  - Continue owning the app entry point and `MenuBarExtra` mounting.
  - Add a `NowThereMenuBarLabel.view(for:)` helper that returns the styled text view.
  - Use AppKit's regular system font size and SwiftUI `.primary` foreground style.

- `Tests/NowThereAppTests/MenuBarTitleTests.swift`
  - Keep existing title string tests.
  - Add a lightweight construction test for the styled label helper so the helper remains callable from tests and the app target keeps compiling through the appearance path.

---

### Task 1: Style Menu Bar Label

**Files:**
- Modify: `Sources/NowThere/NowThereApp.swift`
- Test: `Tests/NowThereAppTests/MenuBarTitleTests.swift`

**Interfaces:**
- Consumes:
  - `NowThereMenuBarLabel.title(for viewModel: ClockViewModel) -> String`
  - `ClockViewModel.menuTitle`
  - `NSFont.systemFontSize(for: .regular)`
- Produces:
  - `@MainActor static func NowThereMenuBarLabel.view(for viewModel: ClockViewModel) -> some View`
  - `MenuBarExtra` label closure calls `NowThereMenuBarLabel.view(for: viewModel)`

- [ ] **Step 1: Write the failing app-level construction test**

Add this test to `Tests/NowThereAppTests/MenuBarTitleTests.swift` after `testMenuBarLabelIncludesCustomLabelFromViewModel()`:

```swift
    func testMenuBarLabelViewCanBeBuiltFromViewModel() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)

        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        _ = NowThereMenuBarLabel.view(for: viewModel)

        XCTAssertEqual(NowThereMenuBarLabel.title(for: viewModel), "Tokyo Jul 08 Wed 12:34")
    }
```

- [ ] **Step 2: Run app tests and verify failure**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: FAIL with a compiler error that `NowThereMenuBarLabel` has no member `view`.

- [ ] **Step 3: Add the styled label helper**

In `Sources/NowThere/NowThereApp.swift`, replace the `MenuBarExtra` label closure:

```swift
        } label: {
            Text(NowThereMenuBarLabel.title(for: viewModel))
        }
```

with:

```swift
        } label: {
            NowThereMenuBarLabel.view(for: viewModel)
        }
```

Then update `NowThereMenuBarLabel` to include the helper:

```swift
enum NowThereMenuBarLabel {
    @MainActor
    static func title(for viewModel: ClockViewModel) -> String {
        viewModel.menuTitle
    }

    @MainActor
    static func view(for viewModel: ClockViewModel) -> some View {
        Text(title(for: viewModel))
            .font(.system(size: NSFont.systemFontSize(for: .regular), weight: .regular))
            .foregroundStyle(.primary)
    }
}
```

- [ ] **Step 4: Run app tests and verify pass**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: PASS.

- [ ] **Step 5: Run full tests and build**

Run:

```bash
swift test
swift build --product NowThere
```

Expected: both commands pass.

- [ ] **Step 6: Commit the implementation**

Run:

```bash
git add Sources/NowThere/NowThereApp.swift Tests/NowThereAppTests/MenuBarTitleTests.swift
git commit -m "fix: align menu bar label appearance with system clock" -m "AI-Co-Authored-By: Codex"
```

---

## Final Verification

- [ ] Run focused app tests:

```bash
swift test --filter MenuBarTitleTests
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

- [ ] Manual visual check:

```bash
scripts/build-app-bundle.sh debug
open .build/debug/NowThere.app
```

Expected: The NowThere menu bar title uses system-managed primary text color and regular system font, making it visually closer to the system clock in normal non-highlighted state.
