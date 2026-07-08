# Task 2 结果报告

## What you implemented
- 在 `Sources/NowThereCore/TimeZoneStore.swift` 新增 `TimeZoneStoreKeys.customLabel`
- 在 `Sources/NowThereCore/TimeZoneStore.swift` 新增：
  - `loadCustomLabel() -> String`
  - `saveCustomLabel(_:)`
- 在 `Sources/NowThereCore/ClockViewModel.swift` 新增：
  - `@Published public private(set) var customLabel: String`
  - `setCustomLabel(_:)`
- 初始化与 `refresh()` 均已改为通过 `ClockFormatter.title(for:timeZone:visibility:customLabel:)` 传入持久化标签
- 在测试中补齐 store 与 view model 的 custom label 持久化、初始化、刷新和全字段隐藏场景

## What you tested and test results

### RED
1. `swift test --filter TimeZoneStoreTests`
2. `swift test --filter ClockViewModelTests`

首次在受限沙箱内运行时被 SwiftPM manifest/cache 权限拦截，因此按任务说明改用：

1. `HOME=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/nowthere-clang-cache SWIFT_MODULE_CACHE_PATH=/private/tmp/nowthere-swift-module-cache SWIFT_CACHE_DIR=/private/tmp/nowthere-swift-cache SWIFTPM_CACHE_PATH=/private/tmp/nowthere-swiftpm-cache SWIFT_USER_STATE_DIR=/private/tmp/nowthere-swift-user-state swift test --filter TimeZoneStoreTests`
2. `HOME=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/nowthere-clang-cache SWIFT_MODULE_CACHE_PATH=/private/tmp/nowthere-swift-module-cache SWIFT_CACHE_DIR=/private/tmp/nowthere-swift-cache SWIFTPM_CACHE_PATH=/private/tmp/nowthere-swiftpm-cache SWIFT_USER_STATE_DIR=/private/tmp/nowthere-swift-user-state swift test --filter ClockViewModelTests`

失败结果符合预期，关键编译错误包括：
- `value of type 'TimeZoneStore' has no member 'loadCustomLabel'`
- `value of type 'TimeZoneStore' has no member 'saveCustomLabel'`
- `type 'TimeZoneStoreKeys' has no member 'customLabel'`
- `value of type 'ClockViewModel' has no member 'customLabel'`
- `value of type 'ClockViewModel' has no member 'setCustomLabel'`

### GREEN
1. `HOME=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/nowthere-clang-cache SWIFT_MODULE_CACHE_PATH=/private/tmp/nowthere-swift-module-cache SWIFT_CACHE_DIR=/private/tmp/nowthere-swift-cache SWIFTPM_CACHE_PATH=/private/tmp/nowthere-swiftpm-cache SWIFT_USER_STATE_DIR=/private/tmp/nowthere-swift-user-state swift test --filter TimeZoneStoreTests`
   - `Executed 7 tests, with 0 failures`
2. `HOME=/private/tmp CLANG_MODULE_CACHE_PATH=/private/tmp/nowthere-clang-cache SWIFT_MODULE_CACHE_PATH=/private/tmp/nowthere-swift-module-cache SWIFT_CACHE_DIR=/private/tmp/nowthere-swift-cache SWIFTPM_CACHE_PATH=/private/tmp/nowthere-swiftpm-cache SWIFT_USER_STATE_DIR=/private/tmp/nowthere-swift-user-state swift test --filter ClockViewModelTests`
   - `Executed 10 tests, with 0 failures`

## TDD Evidence
- 先补了 `TimeZoneStoreTests` 与 `ClockViewModelTests` 中的 custom label 相关测试
- 在没有生产代码前重新运行聚焦测试，确认红灯是因为缺失的 store/view model 接口
- 以最小实现补齐接口后复跑聚焦测试，得到绿灯

## Files changed
- `Sources/NowThereCore/TimeZoneStore.swift`
- `Sources/NowThereCore/ClockViewModel.swift`
- `Sources/NowThereCore/ClockFormatter.swift`
- `Tests/NowThereCoreTests/TimeZoneStoreTests.swift`
- `Tests/NowThereCoreTests/ClockViewModelTests.swift`
- `.superpowers/sdd/task-2-report.md`

## Self-review findings, if any
- `customLabel` 状态只在 `ClockViewModel` 内新增一条持久化通道，没有改动 UI 层接口
- `setCustomLabel(_:)` 与 `selectTimeZone` / `setField` 保持同样的“更新状态 -> 存储 -> refresh”模式
- `ClockFormatter` 加了一处很小的兼容修正：当系统把 `TimeZone(identifier: "UTC")` 规范化为 `GMT` 且 offset 为 0 时，标题标签统一显示为 `UTC`

## Any issues or concerns
- 为满足 brief 中 `Work UTC Jul 08 Wed 03:34` 的精确期望值，额外修改了 `Sources/NowThereCore/ClockFormatter.swift`。根因是当前 macOS 运行时会把 `TimeZone(identifier: "UTC")` 规范化成 `GMT`，导致现有 `cityLabel(for:)` 输出 `GMT`。这个改动很小，但确实超出了 brief 中列出的两处实现文件。
- 本地 SwiftPM 在受限沙箱下会因为 manifest/cache 权限失败，测试验证依赖任务里给出的缓存重定向命令并在沙箱外执行。
