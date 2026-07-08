# NowThere AppKit Status Item Design

## Summary

NowThere should switch the menu bar title from SwiftUI `MenuBarExtra` label rendering to an AppKit-backed `NSStatusItem`. The goal is to let AppKit render the status item text through the native status bar button path, which should better match the system clock color and weight than SwiftUI `Text` inside `MenuBarExtra`.

## Root Cause

Applying `.foregroundStyle(.primary)` and a regular 13pt system font to the SwiftUI `MenuBarExtra` label did not make the title match the system clock. AppKit inspection shows `NSFont.systemFontSize(for: .regular)` and `NSFont.menuBarFont(ofSize: 0)` both resolve to `.AppleSystemUIFont 13pt` regular weight, so the remaining mismatch is likely the SwiftUI `MenuBarExtra` label rendering path rather than the chosen font.

## Goals

- Render the menu bar title using native `NSStatusItem` button text.
- Keep the current title string generation, title styles, persistence, and menu content behavior.
- Let AppKit manage status item text color for normal and highlighted states.
- Reuse the existing SwiftUI `MenuBarContentView` inside an `NSPopover`.

## Non-Goals

- No custom fixed text color.
- No semibold/bold title weight.
- No custom drawing, shadow, glow, background, border, or capsule.
- No redesign of the menu content.
- No change to `ClockFormatter`, `TitleStyle`, `TimeZoneStore`, or saved preferences.

## Architecture

Replace the `MenuBarExtra` scene with an AppKit status bar controller:

- `NowThereApp`
  - Keeps the SwiftUI app lifecycle.
  - Uses `@NSApplicationDelegateAdaptor` to install an AppKit app delegate.
  - Provides no user-facing window scene.

- `NowThereAppDelegate`
  - Creates the shared `ClockViewModel`.
  - Creates and retains a `NowThereStatusBarController`.

- `NowThereStatusBarController`
  - Owns an `NSStatusItem`.
  - Sets `statusItem.button?.title` from `ClockViewModel.menuTitle`.
  - Uses `NSFont.menuBarFont(ofSize: 0)` for the button font.
  - Observes the view model and updates the status item title after menu title changes.
  - Owns an `NSPopover` whose content is `NSHostingController(rootView: MenuBarContentView(viewModel: viewModel))`.
  - Toggles the popover when the status item is clicked.

- `NowThereMenuBarLabel`
  - Remains a small helper for title extraction.
  - Adds a testable helper that configures native status button title and font.

## Data Flow

On launch:

1. App delegate creates `ClockViewModel`.
2. Status bar controller creates an `NSStatusItem`.
3. Controller applies the initial `viewModel.menuTitle` to the status item button.
4. Controller embeds `MenuBarContentView` in an `NSPopover`.
5. Controller observes `viewModel.objectWillChange` and schedules title updates after model changes publish.

On click:

1. Status item button invokes the controller action.
2. Controller closes the popover if it is open.
3. Otherwise, controller shows the popover relative to the status item button.

## Testing Strategy

Automated tests:

- Existing app-level title string tests continue to pass.
- Add a testable status button display protocol and fake display object.
- Verify `NowThereMenuBarLabel.configure(_:title:)` sets the button title.
- Verify it uses `NSFont.menuBarFont(ofSize: 0)` rather than a custom font.

Manual acceptance checks:

- Build and run the app bundle.
- Verify the menu bar title visually matches the system clock more closely in normal non-highlighted state.
- Click the title and verify the existing menu content appears in a popover.
- Change title style or time zone and verify the status item title updates.
