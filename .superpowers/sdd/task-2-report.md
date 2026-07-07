# Task 2 结果报告

## What you implemented
- 新增 `Sources/NowThereCore/TimeZoneStore.swift`，包含：
  - `TimeZoneStoreKeys` 常量键
  - `TimeZoneStore`
  - `init(defaults:fallbackTimeZone:)`
  - `loadTimeZone()`、`saveTimeZone(_:)`
  - `loadVisibility()`、`saveVisibility(_:)`
  - `bool(forKey:defaultValue:)` 兜底读取工具
- 新增 `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`，新增 5 条测试：
  - `testLoadTimeZoneUsesFallbackWhenNoValueIsSaved`
  - `testLoadTimeZoneRewritesInvalidSavedIdentifierToFallback`
  - `testSaveTimeZonePersistsIdentifier`
  - `testLoadVisibilityDefaultsEveryFieldToVisible`
  - `testSaveVisibilityPersistsFieldSwitches`

## What you tested and test results
- RED：`swift test --filter TimeZoneStoreTests`
  - 预期缺失类型导致编译错误（`TimeZoneStore` / `TimeZoneStoreKeys`）。
- GREEN：`swift test --filter TimeZoneStoreTests`
  - `Executed 5 tests, with 0 failures`
- 全量回归：`swift test`
  - `Executed 9 tests, with 0 failures`

## TDD Evidence

### RED
- Command: `swift test --filter TimeZoneStoreTests`
- Relevant failing output:
  - `error: cannot find 'TimeZoneStore' in scope`
  - `error: cannot find 'TimeZoneStoreKeys' in scope`
- Why this was expected:
  - 按要求先写测试，生产代码尚未实现；测试命名与行为表达了待实现的持久化契约，红灯验证覆盖了“测试先于实现”。

### GREEN
- Command: `swift test --filter TimeZoneStoreTests`
- Relevant passing output:
  - `Test Suite 'TimeZoneStoreTests' passed`
  - `Executed 5 tests, with 0 failures`

## Files changed
- `Sources/NowThereCore/TimeZoneStore.swift`
- `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
- `.superpowers/sdd/task-2-report.md`

## Self-review findings, if any
- `loadTimeZone()` 对无效时区标识进行回退并重写默认值，`loadVisibility()` 对未设置字段采用全部显示默认值。
- 测试文件保留了原始行为结构，并将 `UTC` 的断言改为基于 `utc.identifier`，以规避当前 macOS 运行时将 `UTC` 规范化为 `GMT` 的平台差异。

## Any issues or concerns
- 在本地沙箱环境首次执行 `swift test` 时会触发 SwiftPM manifest 的缓存目录权限问题（`/Users/zhangfan/.cache/clang/ModuleCache` 不可写），需要使用提升权限的执行才能完成验证。该问题不属于业务代码缺陷。
