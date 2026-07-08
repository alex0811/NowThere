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
        customLabel: String = "",
        titleStyle: TitleStyle = .standard,
        timeFormat: TimeFormat = .twentyFourHour,
        locale: Locale? = nil
    ) -> String {
        var nonTimeParts: [String] = []
        let trimmedCustomLabel = customLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleLocale = locale ?? self.locale

        if !trimmedCustomLabel.isEmpty {
            nonTimeParts.append(trimmedCustomLabel)
        }

        if visibility.showsCity {
            nonTimeParts.append(cityLabel(for: timeZone))
        }

        if visibility.showsDate {
            nonTimeParts.append(format(date, format: "MMM dd", timeZone: timeZone, locale: titleLocale))
        }

        if visibility.showsWeekday {
            nonTimeParts.append(format(date, format: "EEE", timeZone: timeZone, locale: titleLocale))
        }

        let timePart = visibility.showsTime ? format(
            date,
            format: timeFormat.dateFormat,
            timeZone: timeZone,
            locale: titleLocale
        ) : nil

        switch titleStyle {
        case .standard:
            var parts = nonTimeParts

            if let timePart {
                parts.append(timePart)
            }

            return title(from: parts)
        case .timeFirst:
            guard let timePart else {
                return title(from: nonTimeParts)
            }

            return title(from: [timePart] + nonTimeParts)
        case .separated:
            guard let timePart else {
                return title(from: nonTimeParts)
            }

            let details = nonTimeParts.joined(separator: " ")
            return details.isEmpty ? timePart : "\(timePart) | \(details)"
        case .bracketed:
            guard let timePart else {
                return title(from: nonTimeParts)
            }

            return title(from: ["[\(timePart)]"] + nonTimeParts)
        }
    }

    private func title(from parts: [String]) -> String {
        guard !parts.isEmpty else {
            return "NowThere"
        }

        return parts.joined(separator: " ")
    }

    public func details(
        for date: Date,
        timeZone: TimeZone,
        timeFormat: TimeFormat = .twentyFourHour
    ) -> ClockDetails {
        ClockDetails(
            label: cityLabel(for: timeZone),
            identifier: timeZone.identifier,
            fullDate: format(date, format: "MMMM d, yyyy", timeZone: timeZone),
            fullWeekday: format(date, format: "EEEE", timeZone: timeZone),
            time: format(date, format: timeFormat.dateFormat, timeZone: timeZone),
            utcOffset: utcOffset(for: date, timeZone: timeZone)
        )
    }

    public func cityLabel(for timeZone: TimeZone) -> String {
        let rawLabel = timeZone.identifier.split(separator: "/").last.map(String.init) ?? timeZone.identifier
        return rawLabel.replacingOccurrences(of: "_", with: " ")
    }

    private func format(_ date: Date, format: String, timeZone: TimeZone) -> String {
        self.format(date, format: format, timeZone: timeZone, locale: locale)
    }

    private func format(_ date: Date, format: String, timeZone: TimeZone, locale: Locale) -> String {
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
