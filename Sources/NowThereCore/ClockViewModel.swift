import Combine
import Foundation

public enum ClockField {
    case city
    case date
    case weekday
    case time
}

public protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public enum LaunchAtLoginError: Equatable, Sendable {
    case updateFailed
}

internal protocol ClockTimerScheduling: AnyObject {
    func schedule(after interval: TimeInterval, repeats: Bool, action: @escaping () -> Void)
}

final class FoundationClockTimerScheduler: ClockTimerScheduling {
    private var timer: Timer?
    private var actionProxy: TimerActionProxy?

    deinit {
        timer?.invalidate()
    }

    func schedule(after interval: TimeInterval, repeats: Bool, action: @escaping () -> Void) {
        timer?.invalidate()
        let proxy = TimerActionProxy(action: action)
        actionProxy = proxy

        let nextTimer = Timer(
            timeInterval: interval,
            target: proxy,
            selector: #selector(TimerActionProxy.fire),
            userInfo: nil,
            repeats: repeats
        )
        timer = nextTimer
        RunLoop.main.add(nextTimer, forMode: .common)
    }

    private final class TimerActionProxy: NSObject {
        private let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func fire() {
            action()
        }
    }
}

@MainActor
public final class ClockViewModel: ObservableObject {
    @Published public private(set) var selectedTimeZone: TimeZone
    @Published public private(set) var now: Date
    @Published public private(set) var visibility: FieldVisibility
    @Published public private(set) var customLabel: String
    @Published public private(set) var titleStyle: TitleStyle
    @Published public private(set) var timeFormat: TimeFormat
    @Published public private(set) var interfaceLanguage: InterfaceLanguage
    @Published public private(set) var menuTitle: String
    @Published public private(set) var isLaunchAtLoginEnabled: Bool
    @Published public private(set) var launchAtLoginError: LaunchAtLoginError?

    private let store: TimeZoneStore
    private let formatter: ClockFormatter
    private let search: TimeZoneSearch
    private let loginItemManager: LoginItemManaging
    private let nowProvider: () -> Date
    private let timerScheduler: ClockTimerScheduling

    public convenience init(
        store: TimeZoneStore = TimeZoneStore(),
        formatter: ClockFormatter = ClockFormatter(),
        search: TimeZoneSearch = TimeZoneSearch(),
        loginItemManager: LoginItemManaging,
        nowProvider: @escaping () -> Date = Date.init,
        startsTimer: Bool = true
    ) {
        self.init(
            store: store,
            formatter: formatter,
            search: search,
            loginItemManager: loginItemManager,
            nowProvider: nowProvider,
            timerScheduler: FoundationClockTimerScheduler(),
            startsTimer: startsTimer
        )
    }

    init(
        store: TimeZoneStore = TimeZoneStore(),
        formatter: ClockFormatter = ClockFormatter(),
        search: TimeZoneSearch = TimeZoneSearch(),
        loginItemManager: LoginItemManaging,
        nowProvider: @escaping () -> Date = Date.init,
        timerScheduler: ClockTimerScheduling,
        startsTimer: Bool = true
    ) {
        self.store = store
        self.formatter = formatter
        self.search = search
        self.loginItemManager = loginItemManager
        self.nowProvider = nowProvider
        self.timerScheduler = timerScheduler

        let loadedTimeZone = store.loadTimeZone()
        let loadedVisibility = store.loadVisibility()
        let loadedCustomLabel = store.loadCustomLabel()
        let loadedTitleStyle = store.loadTitleStyle()
        let loadedTimeFormat = store.loadTimeFormat()
        let loadedInterfaceLanguage = store.loadInterfaceLanguage()
        let initialDate = nowProvider()

        self.selectedTimeZone = loadedTimeZone
        self.visibility = loadedVisibility
        self.customLabel = loadedCustomLabel
        self.titleStyle = loadedTitleStyle
        self.timeFormat = loadedTimeFormat
        self.interfaceLanguage = loadedInterfaceLanguage
        self.now = initialDate
        self.menuTitle = formatter.title(
            for: initialDate,
            timeZone: loadedTimeZone,
            visibility: loadedVisibility,
            customLabel: loadedCustomLabel,
            titleStyle: loadedTitleStyle,
            timeFormat: loadedTimeFormat,
            locale: Self.menuTitleLocale(for: loadedInterfaceLanguage)
        )
        self.isLaunchAtLoginEnabled = loginItemManager.isEnabled
        self.launchAtLoginError = nil

        if startsTimer {
            startTimer()
        }
    }

    public var details: ClockDetails {
        formatter.details(for: now, timeZone: selectedTimeZone, timeFormat: timeFormat)
    }

    public func refresh() {
        now = nowProvider()
        menuTitle = formatter.title(
            for: now,
            timeZone: selectedTimeZone,
            visibility: visibility,
            customLabel: customLabel,
            titleStyle: titleStyle,
            timeFormat: timeFormat,
            locale: Self.menuTitleLocale(for: interfaceLanguage)
        )
    }

    public func selectTimeZone(identifier: String) {
        guard let timeZone = TimeZone(identifier: identifier) else {
            return
        }

        selectedTimeZone = timeZone
        store.saveTimeZone(timeZone)
        refresh()
    }

    public func setCustomLabel(_ label: String) {
        customLabel = label
        store.saveCustomLabel(label)
        refresh()
    }

    public func setTitleStyle(_ titleStyle: TitleStyle) {
        self.titleStyle = titleStyle
        store.saveTitleStyle(titleStyle)
        refresh()
    }

    public func setTimeFormat(_ timeFormat: TimeFormat) {
        self.timeFormat = timeFormat
        store.saveTimeFormat(timeFormat)
        refresh()
    }

    public func setInterfaceLanguage(_ interfaceLanguage: InterfaceLanguage) {
        self.interfaceLanguage = interfaceLanguage
        store.saveInterfaceLanguage(interfaceLanguage)
        refresh()
    }

    public func setField(_ field: ClockField, isVisible: Bool) {
        var nextVisibility = visibility

        switch field {
        case .city:
            nextVisibility.showsCity = isVisible
        case .date:
            nextVisibility.showsDate = isVisible
        case .weekday:
            nextVisibility.showsWeekday = isVisible
        case .time:
            nextVisibility.showsTime = isVisible
        }

        visibility = nextVisibility
        store.saveVisibility(nextVisibility)
        refresh()
    }

    public func searchResults(matching query: String) -> [TimeZoneSearchResult] {
        search.results(matching: query)
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginError = nil
        } catch {
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginError = .updateFailed
        }
    }

    public var launchAtLoginErrorMessage: String? {
        guard launchAtLoginError != nil else {
            return nil
        }

        return "Could not update launch setting"
    }

    private func startTimer() {
        let initialDelay = secondsUntilNextMinute(from: now)
        timerScheduler.schedule(after: initialDelay, repeats: false) { [weak self] in
            self?.refreshAfterMinuteBoundary()
        }
    }

    private static func menuTitleLocale(for interfaceLanguage: InterfaceLanguage) -> Locale {
        switch interfaceLanguage {
        case .system:
            .autoupdatingCurrent
        case .english:
            Locale(identifier: "en_US_POSIX")
        case .simplifiedChinese:
            Locale(identifier: "zh-Hans")
        case .japanese:
            Locale(identifier: "ja")
        }
    }

    private func refreshAfterMinuteBoundary() {
        refresh()
        timerScheduler.schedule(after: 60, repeats: true) { [weak self] in
            self?.refresh()
        }
    }
}

internal func secondsUntilNextMinute(
    from date: Date,
    calendar: Calendar = .current
) -> TimeInterval {
    let seconds = TimeInterval(calendar.component(.second, from: date))
    let nanoseconds = TimeInterval(calendar.component(.nanosecond, from: date)) / 1_000_000_000
    let elapsed = seconds + nanoseconds
    let remaining = 60 - elapsed

    return remaining == 0 ? 60 : remaining
}
