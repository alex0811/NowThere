# NowThere Menu Bar Label Appearance Design

## Summary

NowThere's menu bar title should visually match the system clock more closely in normal, non-highlighted menu bar state. The first fix should use system-provided text styling rather than custom colors or a custom status item view.

## Problem

The current `MenuBarExtra` label uses a plain SwiftUI `Text`. In screenshots, NowThere's title appears lighter than the system clock, making the time harder to read against photo or low-contrast desktop backgrounds.

## Goals

- Make the NowThere menu bar title closer to the system clock's color and weight.
- Preserve automatic light/dark appearance adaptation.
- Keep the title text-only and compatible with existing title styles.
- Avoid making the title look intentionally highlighted or custom-branded.

## Non-Goals

- No custom fixed text color.
- No heavier-than-system emphasis such as semibold or bold.
- No background, border, capsule, shadow, or glow.
- No replacement of `MenuBarExtra` with a custom `NSStatusItem` view in this first pass.
- No change to title formatting, title style options, or persisted preferences.

## Design

Update the `MenuBarExtra` label to explicitly use:

- `foregroundStyle(.primary)`
- system regular menu bar-sized font

The intended implementation shape is:

```swift
Text(NowThereMenuBarLabel.title(for: viewModel))
    .font(.system(size: NSFont.systemFontSize(for: .regular), weight: .regular))
    .foregroundStyle(.primary)
```

`foregroundStyle(.primary)` keeps the color system-managed. The explicit regular system font avoids accidental inherited styling while staying close to AppKit's standard menu bar text treatment.

## Fallback Decision

If this does not visually match the system clock closely enough after manual inspection, the next design should evaluate an AppKit-backed `NSStatusItem` label. That is deliberately out of scope for this first pass because it has higher implementation risk and could duplicate behavior SwiftUI already provides.

## Testing Strategy

Automated tests should stay focused on behavior:

- Existing menu bar title string tests should continue to pass.
- No formatter, persistence, or title style behavior should change.

Manual acceptance checks:

- Build and run the app.
- Compare the NowThere menu bar title with the system clock in normal non-highlighted state.
- Verify the title remains readable on a photo desktop background.
- Verify the title still adapts when macOS appearance changes between light and dark.
