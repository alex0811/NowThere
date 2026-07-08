# AppKit Status Item Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace SwiftUI `MenuBarExtra` label rendering with a native AppKit `NSStatusItem` while reusing existing title generation and SwiftUI menu content.

**Architecture:** Keep `ClockViewModel` and `MenuBarContentView` unchanged. Add an AppKit status bar controller that owns `NSStatusItem` and `NSPopover`, and update `NowThereApp` to install that controller through an app delegate.

**Tech Stack:** Swift 6, AppKit `NSStatusItem`/`NSPopover`, SwiftUI `NSHostingController`, Combine, XCTest, Swift Package Manager.

## Global Constraints

- Render the menu bar title using native `NSStatusItem` button text.
- Keep current title string generation, title styles, persistence, and menu content behavior.
- Let AppKit manage status item text color for normal and highlighted states.
- Reuse existing `MenuBarContentView` inside an `NSPopover`.
- No custom fixed text color.
- No semibold/bold title weight.
- No custom drawing, shadow, glow, background, border, or capsule.
- No redesign of the menu content.
- No change to `ClockFormatter`, `TitleStyle`, `TimeZoneStore`, or saved preferences.

---

### Task 1: Add Native Status Item Shell

**Files:**
- Modify: `Sources/NowThere/NowThereApp.swift`
- Create: `Sources/NowThere/NowThereStatusBarController.swift`
- Test: `Tests/NowThereAppTests/MenuBarTitleTests.swift`

**Interfaces:**
- Produces:
  - `@MainActor protocol MenuBarTitleDisplaying`
  - `@MainActor static func NowThereMenuBarLabel.configure(_ display: MenuBarTitleDisplaying?, title: String)`
  - `@MainActor final class NowThereStatusBarController: NSObject`
  - `@MainActor final class NowThereAppDelegate: NSObject, NSApplicationDelegate`

- [ ] **Step 1: Write failing title display test**

In `Tests/NowThereAppTests/MenuBarTitleTests.swift`, replace `testMenuBarLabelViewCanBeBuiltFromViewModel()` with:

```swift
    func testMenuBarLabelConfiguresNativeStatusButtonAppearance() {
        let display = FakeMenuBarTitleDisplay()

        NowThereMenuBarLabel.configure(display, title: "Tokyo Jul 08 Wed 12:34")

        let expectedFont = NSFont.menuBarFont(ofSize: 0)
        XCTAssertEqual(display.title, "Tokyo Jul 08 Wed 12:34")
        XCTAssertEqual(display.font?.fontName, expectedFont.fontName)
        XCTAssertEqual(display.font?.pointSize, expectedFont.pointSize)
    }
```

Add this fake near the existing fake login manager:

```swift
private final class FakeMenuBarTitleDisplay: MenuBarTitleDisplaying {
    var title = ""
    var font: NSFont?
}
```

Also add `import AppKit` at the top of the test file.

- [ ] **Step 2: Run app tests and verify failure**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: FAIL with missing `MenuBarTitleDisplaying` or `NowThereMenuBarLabel.configure`.

- [ ] **Step 3: Implement native title configuration**

In `Sources/NowThere/NowThereApp.swift`:

- Keep `NowThereMenuBarLabel.title(for:)`.
- Remove `NowThereMenuBarLabel.view(for:)`.
- Add:

```swift
@MainActor
protocol MenuBarTitleDisplaying: AnyObject {
    var title: String { get set }
    var font: NSFont? { get set }
}

extension NSStatusBarButton: MenuBarTitleDisplaying {}
```

- Add to `NowThereMenuBarLabel`:

```swift
    @MainActor
    static func configure(_ display: MenuBarTitleDisplaying?, title: String) {
        guard let display else {
            return
        }

        display.title = title
        display.font = NSFont.menuBarFont(ofSize: 0)
    }
```

- [ ] **Step 4: Add AppKit status bar controller**

Create `Sources/NowThere/NowThereStatusBarController.swift`:

```swift
import AppKit
import Combine
import NowThereCore
import SwiftUI

@MainActor
final class NowThereStatusBarController: NSObject {
    private let viewModel: ClockViewModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var viewModelCancellable: AnyCancellable?

    init(
        viewModel: ClockViewModel,
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        popover: NSPopover = NSPopover()
    ) {
        self.viewModel = viewModel
        self.statusItem = statusItem
        self.popover = popover
        super.init()

        configureStatusItem()
        configurePopover()
        observeViewModel()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        NowThereMenuBarLabel.configure(button, title: viewModel.menuTitle)
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(viewModel: viewModel)
        )
    }

    private func observeViewModel() {
        viewModelCancellable = viewModel.objectWillChange.sink { [weak self, weak viewModel] _ in
            Task { @MainActor [weak self, weak viewModel] in
                guard let self, let viewModel else {
                    return
                }

                self.updateTitle(viewModel.menuTitle)
            }
        }
    }

    private func updateTitle(_ title: String) {
        NowThereMenuBarLabel.configure(statusItem.button, title: title)
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
}
```

- [ ] **Step 5: Replace `MenuBarExtra` app entry with app delegate**

In `Sources/NowThere/NowThereApp.swift`, replace the `NowThereApp` body/state with:

```swift
@MainActor
@main
struct NowThereApp: App {
    @NSApplicationDelegateAdaptor(NowThereAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class NowThereAppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: NowThereStatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let viewModel = ClockViewModel(loginItemManager: SystemLoginItemManager())
        statusBarController = NowThereStatusBarController(viewModel: viewModel)
    }
}
```

- [ ] **Step 6: Run focused tests and fix compile issues**

Run:

```bash
swift test --filter MenuBarTitleTests
```

Expected: PASS.

- [ ] **Step 7: Run full tests and build**

Run:

```bash
swift test
swift build --product NowThere
scripts/build-app-bundle.sh debug
```

Expected: all pass.

- [ ] **Step 8: Commit implementation**

Run:

```bash
git add Sources/NowThere/NowThereApp.swift Sources/NowThere/NowThereStatusBarController.swift Tests/NowThereAppTests/MenuBarTitleTests.swift
git commit -m "fix: render menu bar title with native status item" -m "AI-Co-Authored-By: Codex"
```

---

## Manual Verification

Run:

```bash
open .build/debug/NowThere.app
```

Expected:

- Menu bar title text appears closer to the system clock.
- Clicking the title shows the existing menu content in a popover.
- Changing title style, fields, custom label, or time zone updates the status item title.
