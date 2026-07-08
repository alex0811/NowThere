# NowThere Localization Design

## Summary

NowThere should localize the menu UI for English, Simplified Chinese, and Japanese while preserving the current deterministic menu bar clock format. The first implementation follows the macOS system language preference and does not add an in-app language picker.

## Goals

- Localize visible static text in the menu UI.
- Support English, Simplified Chinese, and Japanese.
- Follow the macOS system language automatically.
- Keep the current menu bar title output such as `Tokyo Jul 08 Wed 12:34`.
- Keep date, weekday, city label, time zone search result text, IANA identifiers, and custom user labels unchanged.
- Keep the feature small enough to fit the existing Swift Package and SwiftUI menu structure.

## Non-Goals

- No in-app language selector.
- No persisted language preference.
- No localization of menu bar date or weekday output.
- No localization of city labels or time zone identifiers.
- No locale-aware 12-hour / 24-hour automatic selection.
- No changes to existing time format, title style, field visibility, or launch-at-login behavior.

## Supported Languages

The first implementation ships these app-target localization resources:

- English: `Sources/NowThere/Resources/en.lproj/Localizable.strings`
- Simplified Chinese: `Sources/NowThere/Resources/zh-Hans.lproj/Localizable.strings`
- Japanese: `Sources/NowThere/Resources/ja.lproj/Localizable.strings`

English remains the development and fallback language.

## User-Facing Text Scope

Localize these menu UI strings:

- Detail row labels:
  - `Time Zone`
  - `Date`
  - `Weekday`
  - `Time`
  - `UTC Offset`
- Time zone search:
  - section title `Time Zone`
  - placeholder `Search city or time zone`
  - empty state `No matching time zones`
- Settings:
  - section title `Menu Bar Fields`
  - label `Custom Label`
  - placeholder `Work, Home, Client`
  - picker title `Title Style`
  - picker options `Default`, `Time First`, `Separated`, `Bracketed`
  - picker title `Time Format`
  - picker options `24-hour`, `12-hour`
  - toggles `City/Label`, `Date`, `Weekday`, `Time`
  - toggle `Launch at Login`
  - error `Could not update launch setting`
- Command:
  - `Quit NowThere`

Do not localize dynamic values produced by `ClockFormatter`: selected city label, date, weekday, time, UTC offset, menu bar title, or fallback app name `NowThere`.

## Architecture

Use Apple native localization resources. Add `Localizable.strings` files under `Sources/NowThere/Resources` and configure the `NowThere` executable target to process those resources in `Package.swift`. Keep the existing root `Resources/Info.plist` location for the app bundle build script.

SwiftUI views should reference localization keys rather than hard-coded English copy. For labels that SwiftUI can localize automatically, use `Text("key")`, `Button("key")`, `Toggle("key", ...)`, `Picker("key", ...)`, and `TextField("key", ...)` with stable keys. For strings generated outside SwiftUI view builders, use `String(localized:bundle:)` or a small helper that resolves keys from `Bundle.module`.

Keep `TitleStyle` and `TimeFormat` in `NowThereCore`, but avoid making the core target depend on UI resources. The display label responsibility should move to the app target through small helper functions or extensions so the core enum remains a stable data model.

## Resource Keys

Use semantic keys instead of English sentences as keys. This keeps code stable if copy changes later.

Examples:

- `details.timeZone`
- `details.date`
- `search.placeholder`
- `settings.titleStyle.timeFirst`
- `settings.timeFormat.twentyFourHour`
- `command.quit`
- `launchAtLogin.error.updateFailed`

Every key must be present in all three language files.

## Package Resources

Update `Package.swift` so the executable target includes target-local resources:

```swift
resources: [
    .process("Resources")
]
```

The core target should not process these resources. Tests that need localized strings should target the executable module or a helper exposed from the app target.

Update `scripts/build-app-bundle.sh` to copy the SwiftPM-generated localization resource bundle into `NowThere.app/Contents/Resources` so localized strings work in the packaged `.app`, not only when running the SwiftPM build product directly.

## Existing Behavior

- `ClockFormatter` continues to default to `Locale(identifier: "en_US_POSIX")`.
- Existing formatter tests that expect `Tokyo Jul 08 Wed 12:34` remain valid.
- Existing README language files remain unchanged unless copy needs to mention the new UI localization support.
- User-entered custom labels are displayed exactly as entered, except for existing trimming behavior in menu bar title formatting.
- If the system language is not English, Simplified Chinese, or Japanese, macOS falls back through the app bundle localization fallback behavior.

## Error Handling

- Missing localization keys should be treated as test failures.
- Runtime fallback follows Apple bundle localization behavior.
- Launch-at-login failures keep the same behavior, but the displayed error string is localized through the app target.

## Testing Strategy

Unit tests should cover:

- All expected localization keys exist in English, Simplified Chinese, and Japanese resources.
- `TitleStyle` menu labels resolve to localized English, Simplified Chinese, and Japanese strings from the app bundle helper.
- `TimeFormat` menu labels resolve to localized English, Simplified Chinese, and Japanese strings from the app bundle helper.
- The launch-at-login error message resolves through the localization helper.
- Existing formatter and view model tests continue to pass, proving clock output is not localized by this feature.

Manual acceptance checks:

- With macOS preferred language set to English, the menu UI appears in English.
- With macOS preferred language set to Simplified Chinese, the menu UI appears in Simplified Chinese.
- With macOS preferred language set to Japanese, the menu UI appears in Japanese.
- The menu bar title still uses the current compact English date and weekday format.
- Changing title style, time format, field visibility, time zone, custom label, and launch-at-login still works as before.
