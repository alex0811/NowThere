# NowThere Menu Bar Clock Design

## Summary

NowThere is a native macOS menu bar utility that shows the date, weekday, and time for one selected time zone. It uses a compact English short format in the menu bar, lets the user search and select any system time zone, persists preferences, and can optionally launch at login.

The initial version is intentionally small: one selected time zone, minute-level updates, field visibility toggles, current time details in the menu, and no standalone settings window.

## Goals

- Show a compact menu bar title for a selected time zone, for example `Tokyo Jul 08 Wed 12:34`.
- Default to the system local time zone on first launch.
- Let the user search the full system time zone list by city name or IANA identifier.
- Let the user show or hide these menu bar fields:
  - City/Label
  - Date
  - Weekday
  - Time
- Persist selected time zone and field visibility across launches.
- Provide a `Launch at Login` toggle.
- Show full date/time details for the selected time zone in the menu.
- Provide a quit action from the menu.

## Non-Goals

- No multi-time-zone display.
- No second-level menu bar updates.
- No custom format template in the initial version.
- No independent settings window in the initial version.
- No cross-platform implementation.

## Platform

- App name: `NowThere`.
- Implementation: native macOS SwiftUI app.
- Target environment: the current development machine, macOS 26.4.1 with Xcode 26.5.
- Primary API: SwiftUI `MenuBarExtra`.
- The app should not show a Dock icon.

## Architecture

The app is split into small units with clear responsibilities:

- `NowThereApp`
  - SwiftUI app entry point.
  - Owns the app-level state object.
  - Mounts the `MenuBarExtra`.

- `ClockViewModel`
  - Holds the selected time zone, current date, field visibility configuration, launch-at-login state, and transient error message.
  - Builds the menu bar title and detail display data.
  - Starts a minute-level timer and refreshes immediately on launch.

- `ClockFormatter`
  - Formats the selected date/time into stable English strings.
  - Uses `en_US_POSIX` for menu bar output so the title does not vary with system language.
  - Uses the selected time zone for every displayed date/time value.

- `TimeZoneStore`
  - Wraps `UserDefaults`.
  - Persists `selectedTimeZoneIdentifier` and field visibility values.
  - Validates saved time zone identifiers on load.

- `TimeZoneSearch`
  - Uses `TimeZone.knownTimeZoneIdentifiers`.
  - Filters by IANA identifier and human-friendly city label.

- `LoginItemManager`
  - Wraps macOS launch-at-login APIs, preferably modern `ServiceManagement`.
  - Reports actual launch-at-login state back to the view model.
  - Keeps launch-at-login failures isolated from clock display logic.

## Menu Bar Title

The default menu bar title includes all four fields:

```text
Tokyo Jul 08 Wed 12:34
```

Field behavior:

- `City/Label`: derived from the selected time zone identifier, such as `Tokyo` from `Asia/Tokyo`.
- `Date`: `MMM dd`, such as `Jul 08`.
- `Weekday`: `EEE`, such as `Wed`.
- `Time`: `HH:mm`, such as `12:34`.

If all fields are disabled, the title falls back to:

```text
NowThere
```

The title updates at launch and then once per minute.

## Menu Content

The menu content has three sections.

### Current Time Zone Details

Shows the selected time zone in a readable form:

- Label/City
- IANA time zone identifier
- Full date, such as `July 8, 2026`
- Full weekday, such as `Wednesday`
- Time in `HH:mm`
- UTC offset, such as `UTC+09:00`

### Time Zone Selection

Provides a search field and a filtered list of system time zones.

Search behavior:

- Match by IANA identifier, for example `Asia/Tokyo`.
- Match by city label, for example `Tokyo`.
- Selecting a result immediately saves the selection and refreshes the menu bar title.
- If no results match, show `No matching time zones`.

### Settings and Actions

Provides:

- Field visibility toggles for `City/Label`, `Date`, `Weekday`, and `Time`.
- `Launch at Login` toggle.
- `Quit NowThere` action.

## Data Flow

On launch:

1. Load `selectedTimeZoneIdentifier` from `UserDefaults`.
2. If there is no saved value, use `TimeZone.current.identifier`.
3. If the saved identifier is invalid, fall back to the system local time zone and replace the saved value.
4. Load field visibility settings.
5. If there are no saved field settings, default all four fields to enabled.
6. Query the current launch-at-login state.
7. Refresh the displayed time immediately.
8. Start a minute-level timer.

On user actions:

- Selecting a time zone updates the view model, persists the identifier, and refreshes the title.
- Toggling a field updates the view model, persists the field setting, and refreshes the title.
- Toggling launch-at-login calls `LoginItemManager`, then syncs UI state to the actual system result.

## Error Handling

- Invalid saved time zone:
  - Fall back to the local system time zone.
  - Replace the invalid saved value with the fallback identifier.

- No search results:
  - Show `No matching time zones`.

- All fields disabled:
  - Show `NowThere` in the menu bar.
  - Continue showing complete details inside the menu.

- Launch-at-login update failure:
  - Restore the toggle to the actual launch-at-login state.
  - Show a short transient error in the menu: `Could not update launch setting`.

## Testing Strategy

Unit tests should cover pure logic first:

- `ClockFormatter`
  - Formats a fixed date in `Asia/Tokyo` as English short date, weekday, and time.
  - Builds titles correctly for field visibility combinations.
  - Returns `NowThere` when every field is disabled.

- `TimeZoneStore`
  - Uses the local system time zone when no saved identifier exists.
  - Falls back and rewrites storage when a saved identifier is invalid.
  - Provides correct default field visibility values.

- `TimeZoneSearch`
  - Finds `Asia/Tokyo` by `Tokyo`.
  - Finds `Asia/Tokyo` by `Asia/Tokyo`.
  - Returns an empty list for a query with no matches.

Manual acceptance checks:

- The menu bar shows the local time zone on first launch.
- Selecting a different time zone updates the menu bar title immediately.
- Restarting the app preserves the selected time zone.
- Field toggles update the title immediately and persist across restart.
- Turning all fields off shows `NowThere`.
- The launch-at-login toggle reflects the actual system result.
- `Quit NowThere` exits the app.

## Scope Decision

This is small enough for one implementation plan. The only likely follow-up is moving time zone search into a standalone settings window if the inline menu search feels cramped, but that is explicitly outside the first version.
