import Foundation

public struct FieldVisibility: Equatable, Sendable {
    public var showsCity: Bool
    public var showsDate: Bool
    public var showsWeekday: Bool
    public var showsTime: Bool

    public init(showsCity: Bool, showsDate: Bool, showsWeekday: Bool, showsTime: Bool) {
        self.showsCity = showsCity
        self.showsDate = showsDate
        self.showsWeekday = showsWeekday
        self.showsTime = showsTime
    }

    public static let allVisible = FieldVisibility(
        showsCity: true,
        showsDate: true,
        showsWeekday: true,
        showsTime: true
    )

    public var hasVisibleField: Bool {
        showsCity || showsDate || showsWeekday || showsTime
    }
}

public struct ClockDetails: Equatable {
    public let label: String
    public let identifier: String
    public let fullDate: String
    public let fullWeekday: String
    public let time: String
    public let utcOffset: String

    public init(
        label: String,
        identifier: String,
        fullDate: String,
        fullWeekday: String,
        time: String,
        utcOffset: String
    ) {
        self.label = label
        self.identifier = identifier
        self.fullDate = fullDate
        self.fullWeekday = fullWeekday
        self.time = time
        self.utcOffset = utcOffset
    }
}

public final class ClockFormatter {
    private let locale: Locale
    private let calendarIdentifier: Calendar.Identifier

    public init(
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        calendarIdentifier: Calendar.Identifier = .gregorian
    ) {
        self.locale = locale
        self.calendarIdentifier = calendarIdentifier
    }

    public func title(
        for date: Date,
        timeZone: TimeZone,
        visibility: FieldVisibility,
        customLabel: String = ""
    ) -> String {
        var parts: [String] = []
        let trimmedCustomLabel = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedCustomLabel.isEmpty {
            parts.append(trimmedCustomLabel)
        }

        if visibility.showsCity {
            parts.append(cityLabel(for: timeZone))
        }

        if visibility.showsDate {
            parts.append(format(date, format: "MMM dd", timeZone: timeZone))
        }

        if visibility.showsWeekday {
            parts.append(format(date, format: "EEE", timeZone: timeZone))
        }

        if visibility.showsTime {
            parts.append(format(date, format: "HH:mm", timeZone: timeZone))
        }

        guard !parts.isEmpty else {
            return "NowThere"
        }

        return parts.joined(separator: " ")
    }

    public func details(for date: Date, timeZone: TimeZone) -> ClockDetails {
        ClockDetails(
            label: cityLabel(for: timeZone),
            identifier: timeZone.identifier,
            fullDate: format(date, format: "MMMM d, yyyy", timeZone: timeZone),
            fullWeekday: format(date, format: "EEEE", timeZone: timeZone),
            time: format(date, format: "HH:mm", timeZone: timeZone),
            utcOffset: utcOffset(for: date, timeZone: timeZone)
        )
    }

    public func cityLabel(for timeZone: TimeZone) -> String {
        let rawLabel = timeZone.identifier.split(separator: "/").last.map(String.init) ?? timeZone.identifier
        return rawLabel.replacingOccurrences(of: "_", with: " ")
    }

    private func format(_ date: Date, format: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: calendarIdentifier)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private func utcOffset(for date: Date, timeZone: TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3_600
        let minutes = (absoluteSeconds % 3_600) / 60
        return String(
            format: "UTC%@%02d:%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            sign,
            hours,
            minutes
        )
    }
}
