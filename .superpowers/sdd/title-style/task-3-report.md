## What I implemented

- Added `@Published public private(set) var titleStyle: TitleStyle` to `ClockViewModel`.
- Loaded persisted title style during `ClockViewModel` initialization and threaded it into initial `menuTitle` generation.
- Updated `ClockViewModel.refresh()` to call `ClockFormatter.title(..., titleStyle:)`.
- Added `ClockViewModel.setTitleStyle(_:)` to persist the selection and refresh the title immediately.
- Added a `Picker("Title Style", selection:)` to `MenuBarContentView.settingsSection` using `TitleStyle.allCases` and `displayName`.
- Added view-model tests covering stored initial title style and runtime updates.

## RED and GREEN test evidence

### RED

Command:

```bash
swift test --filter ClockViewModelTests
```

Observed failure before implementation:

- `value of type 'ClockViewModel' has no member 'titleStyle'`
- `value of type 'ClockViewModel' has no member 'setTitleStyle'`

### GREEN

Command:

```bash
swift test --filter ClockViewModelTests
```

Observed pass after implementation:

- `Executed 13 tests, with 0 failures (0 unexpected)`

## Full test/build evidence

Commands and results:

```bash
swift test --filter ClockFormatterTests
```

- Passed: `Executed 12 tests, with 0 failures (0 unexpected)`

```bash
swift test --filter TimeZoneStoreTests
```

- Passed: `Executed 10 tests, with 0 failures (0 unexpected)`

```bash
swift test --filter ClockViewModelTests
```

- Passed: `Executed 13 tests, with 0 failures (0 unexpected)`

```bash
swift test
```

- Passed: `Executed 41 tests, with 0 failures (0 unexpected)`

```bash
swift build --product NowThere
```

- Passed: `Build of product 'NowThere' complete!`

## Files changed

- `Sources/NowThereCore/ClockViewModel.swift`
- `Sources/NowThere/MenuBarContentView.swift`
- `Tests/NowThereCoreTests/ClockViewModelTests.swift`

## Self-review findings

- Scope stayed within the three task-owned files.
- `ClockViewModel` remains the single source of truth for title style state and persistence.
- Menu picker writes through the existing view-model mutation pattern used by custom label and field toggles.
- No unrelated refactors or behavioral changes were introduced.

## Concerns, if any

- None.
