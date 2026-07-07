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
    private var timer: Timer?

    public init(
        store: TimeZoneStore = TimeZoneStore(),
        formatter: ClockFormatter = ClockFormatter(),
        search: TimeZoneSearch = TimeZoneSearch(),
        loginItemManager: LoginItemManaging,
        nowProvider: @escaping () -> Date = Date.init,
        startsTimer: Bool = true
    ) {
        self.store = store
        self.formatter = formatter
        self.search = search
        self.loginItemManager = loginItemManager
        self.nowProvider = nowProvider

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
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
}
