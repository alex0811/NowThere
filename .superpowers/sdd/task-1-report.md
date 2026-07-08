# Task 1 Report: Formatter Custom Label

## Scope

Updated `ClockFormatter.title(for:timeZone:visibility:customLabel:)` so menu-bar title formatting can prepend a trimmed custom label before the city name and other visible fields.

## Files Changed

- `Sources/NowThereCore/ClockFormatter.swift`
- `Tests/NowThereCoreTests/ClockFormatterTests.swift`

## TDD Evidence

### Red

Added formatter tests for:

- custom label before city
- whitespace-only custom label trimming away
- custom label when every clock field is hidden

Ran the focused formatter tests before implementation and confirmed failure due to the missing `customLabel` parameter.

### Green

Implemented the new `customLabel` parameter in `ClockFormatter.title(...)`, trimmed leading/trailing whitespace, prepended the label only when non-empty, and kept the `NowThere` fallback when no parts are visible.

## Verification

Focused test command:

```bash
HOME=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/nowthere-clang-cache SWIFT_MODULE_CACHE_PATH=/private/tmp/nowthere-swift-module-cache SWIFT_CACHE_DIR=/private/tmp/nowthere-swift-cache SWIFTPM_CACHE_PATH=/private/tmp/nowthere-swiftpm-cache SWIFT_USER_STATE_DIR=/private/tmp/nowthere-swift-user-state swift test --filter ClockFormatterTests
```

Result: passed, 7 tests executed, 0 failures.

## Notes

- No persistence, view model, UI, README, or license files were changed.
- The formatter behavior now matches the task brief exactly for title formatting only.
