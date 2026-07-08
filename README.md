# NowThere

Your menu bar knows local time. Now it knows there.

A native macOS menu bar clock for keeping one important time zone visible at a glance.

`scripts/build-app-bundle.sh debug` | `open .build/debug/NowThere.app`

---

## Why NowThere?

Remote teams, travel plans, releases, calls, and friends rarely live in your local time zone. NowThere keeps one chosen place in the macOS menu bar, formatted for quick scanning without opening Calendar, Clock, or a browser tab.

It is intentionally small: one selected time zone, a compact title, searchable system time zones, and a menu for the details you need.

## Highlights

### One clock, always visible

NowThere shows a compact text clock directly in the menu bar, such as:

```text
Tokyo Jul 08 Wed 12:34
```

The title updates on minute boundaries, so it stays stable without second-by-second movement.

### Search every system time zone

Pick from macOS' full time zone list. Search by city label, such as `Tokyo`, or by IANA identifier, such as `Asia/Tokyo`.

### Shape the menu bar title

Toggle each title field independently:

- City/Label
- Date
- Weekday
- Time

If every field is hidden, NowThere falls back to the app name instead of leaving an empty menu bar item.

### Details on click

Open the menu to see the selected time zone's full details:

- City label
- IANA time zone identifier
- Full date
- Full weekday
- Time
- UTC offset

### Native macOS

NowThere is a small SwiftUI menu bar app. It uses `MenuBarExtra`, stores preferences in `UserDefaults`, and packages as an `LSUIElement` app so it does not appear in the Dock.

## Install

There is no signed release build yet. Build and run locally:

```bash
scripts/build-app-bundle.sh debug
open .build/debug/NowThere.app
```

If an older copy is already running:

```bash
pkill NowThere
open .build/debug/NowThere.app
```

## Requirements

- macOS 13+
- Xcode with Swift 6 toolchain

The project was built and tested on macOS 26.4.1 with Xcode 26.5.

## For Developers

Build the executable:

```bash
swift build --product NowThere
```

Run tests:

```bash
swift test
```

Build the app bundle:

```bash
scripts/build-app-bundle.sh debug
```

Verify the menu bar bundle flag:

```bash
/usr/libexec/PlistBuddy -c "Print :LSUIElement" .build/debug/NowThere.app/Contents/Info.plist
```

Expected output:

```text
true
```

## Current Scope

NowThere currently focuses on one selected time zone. It does not support multiple clocks, second-level updates, or custom format templates.
