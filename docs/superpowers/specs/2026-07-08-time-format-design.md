# NowThere Time Format Design

## Summary

NowThere should let users switch displayed clock time between 24-hour and 12-hour formats. The setting is explicit, persisted, defaults to the existing 24-hour behavior, and affects both the menu bar title and the menu detail `Time` row.

## Goals

- Add a user-controlled `Time Format` setting with `24-hour` and `12-hour` options.
- Preserve the current default output such as `Tokyo Jul 08 Wed 12:34`.
- Apply the selected format consistently to the menu bar title and detail `Time` row.
- Persist the selected format across launches.
- Keep existing field visibility and title style behavior unchanged.

## Non-Goals

- No automatic following of the macOS system time format.
- No separate time format settings for the menu bar title and detail row.
- No seconds display.
- No custom free-form date/time template.
- No change to date, weekday, UTC offset, or time zone search behavior.

## Time Formats

The first implementation supports two formats:

- `24-hour`: `12:34`
- `12-hour`: `12:34 PM`

The app keeps using the existing `en_US_POSIX` locale for deterministic English output. Midnight and single-digit hours should follow the selected format:

- `24-hour`: `00:05`, `09:05`, `21:05`
- `12-hour`: `12:05 AM`, `9:05 AM`, `9:05 PM`

## Menu UI

Add a `Time Format` picker to the existing `Menu Bar Fields` section near `Title Style`. The picker contains:

- `24-hour`
- `12-hour`

Changing the picker immediately refreshes the menu bar title and the detail `Time` row.

## Data Model

Add a `TimeFormat` enum in `NowThereCore` with stable raw string values:

- `twentyFourHour`
- `twelveHour`

`TimeZoneStore` persists the selected value in `UserDefaults`. Missing values default to `twentyFourHour`. Invalid saved values fall back to `twentyFourHour` and are rewritten.

`ClockViewModel` owns the current time format, exposes it to SwiftUI, and refreshes formatted output when it changes.

`ClockFormatter.title(...)` and `ClockFormatter.details(...)` accept the format and use it when rendering clock time.

## Existing Behavior

- Existing title styles continue to decide where the time appears.
- If the `Time` field is hidden, title output remains unchanged by time format.
- If all clock fields are hidden and there is no custom label, the title remains `NowThere`.
- Custom labels, date visibility, weekday visibility, and city visibility keep their current behavior.

## Error Handling

- Missing saved format:
  - Use `24-hour`.
- Invalid saved format:
  - Fall back to `24-hour`.
  - Replace the invalid stored value with `twentyFourHour`.

## Testing Strategy

Unit tests should cover:

- Formatter defaults to 24-hour output.
- Formatter renders 12-hour output in the title.
- Formatter renders 12-hour output in the detail `Time` row.
- Midnight and single-digit hours format correctly in 12-hour mode.
- Hidden `Time` field keeps title output independent of time format.
- Store persists and reloads the selected time format.
- Store falls back and rewrites invalid saved values.
- View model loads the saved format, refreshes the initial title, and updates title/details when the format changes.

Manual acceptance checks:

- Switching `Time Format` updates the menu bar title immediately.
- The detail `Time` row updates while the menu is open.
- Restarting the app preserves the selected format.
- Existing `Title Style` options still combine correctly with both time formats.
