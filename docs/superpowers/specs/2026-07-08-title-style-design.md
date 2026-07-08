# NowThere Title Style Design

## Summary

NowThere should let users choose how the menu bar title is arranged so the time is easier to find at a glance. The feature adds a persisted `Title Style` setting while keeping the current title format as the default.

## Goals

- Let users switch the menu bar title layout from the menu.
- Preserve the current default output: `Tokyo Jul 08 Wed 12:34`.
- Add time-forward options that make `12:34` easier to locate.
- Keep existing field visibility toggles working.
- Persist the selected style across launches.

## Non-Goals

- No rich text, partial background, or true bordered capsule inside the menu bar title.
- No custom free-form format template.
- No new settings window.
- No change to the detailed menu content.

## Title Styles

The first implementation supports four text-only styles:

- `Default`: `Tokyo Jul 08 Wed 12:34`
- `Time First`: `12:34 Tokyo Jul 08 Wed`
- `Separated`: `12:34 | Tokyo Jul 08 Wed`
- `Bracketed`: `[12:34] Tokyo Jul 08 Wed`

Text-only styles are intentional. macOS menu bar titles need to stay compact and native-looking, and a real partial border around only the time would be less reliable than plain text across system appearances and font metrics.

## Field Visibility Behavior

The existing `City/Label`, `Date`, `Weekday`, and `Time` toggles continue to decide which fields are available for the title.

Style behavior:

- `Default` keeps the current field order: custom label, city, date, weekday, time.
- The time-focused styles only move or decorate the time when the `Time` field is visible.
- If `Time` is hidden, time-focused styles fall back to the non-time fields in default order.
- If every clock field is hidden and there is no custom label, the title remains `NowThere`.
- If every clock field is hidden but a custom label exists, the title remains that custom label.

The custom label stays before the city/date/weekday group in all styles. For example, `Time First` with custom label `Work` becomes:

```text
12:34 Work Tokyo Jul 08 Wed
```

## Menu UI

Add a `Title Style` picker to the existing `Menu Bar Fields` section. The picker contains:

- Default
- Time First
- Separated
- Bracketed

Selecting a style immediately updates the menu bar title and persists the choice.

## Data Model

Add a `TitleStyle` enum in `NowThereCore` with stable raw string values:

- `default`
- `timeFirst`
- `separated`
- `bracketed`

`TimeZoneStore` persists the selected value in `UserDefaults`. Invalid saved values fall back to `default` and are rewritten.

`ClockViewModel` owns the current style, exposes it to SwiftUI, and refreshes the title when it changes.

`ClockFormatter.title(...)` accepts the style and applies it after formatting each visible field.

## Error Handling

- Invalid saved style:
  - Fall back to `default`.
  - Replace the invalid stored value with `default`.
- Hidden time field:
  - Do not show separators or brackets for a missing time value.
  - Return the remaining fields in default order.

## Testing Strategy

Unit tests should cover:

- Default style preserves existing title output.
- `Time First` formats as `12:34 Tokyo Jul 08 Wed`.
- `Separated` formats as `12:34 | Tokyo Jul 08 Wed`.
- `Bracketed` formats as `[12:34] Tokyo Jul 08 Wed`.
- Time-focused styles fall back cleanly when the time field is hidden.
- Custom labels combine correctly with time-focused styles.
- Store persists and reloads the selected style.
- Store falls back and rewrites invalid style values.

Manual acceptance checks:

- Switching `Title Style` updates the menu bar title immediately.
- Restarting the app preserves the selected style.
- Existing field toggles still update the title immediately.
- Hiding `Time` removes all time-specific separators or brackets.
