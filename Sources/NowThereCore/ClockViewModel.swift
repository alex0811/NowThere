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
    @Published public private(set) var menuTitle: String
    @Published public private(set) var isLaunchAtLoginEnabled: Bool
    @Published public private(set) var launchAtLoginErrorMessage: String?

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
        let initialDate = nowProvider()

        self.selectedTimeZone = loadedTimeZone
        self.visibility = loadedVisibility
        self.now = initialDate
        self.menuTitle = formatter.title(
            for: initialDate,
            timeZone: loadedTimeZone,
            visibility: loadedVisibility
        )
        self.isLaunchAtLoginEnabled = loginItemManager.isEnabled
        self.launchAtLoginErrorMessage = nil

        if startsTimer {
            startTimer()
        }
    }

    public var details: ClockDetails {
        formatter.details(for: now, timeZone: selectedTimeZone)
    }

    public func refresh() {
        now = nowProvider()
        menuTitle = formatter.title(
            for: now,
            timeZone: selectedTimeZone,
            visibility: visibility
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
            launchAtLoginErrorMessage = nil
        } catch {
            isLaunchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginErrorMessage = "Could not update launch setting"
        }
    }

    private func startTimer() {
        let initialDelay = secondsUntilNextMinute(from: now)
        timerScheduler.schedule(after: initialDelay, repeats: false) { [weak self] in
            self?.refreshAfterMinuteBoundary()
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
