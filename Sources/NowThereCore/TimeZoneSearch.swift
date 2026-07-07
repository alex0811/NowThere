import Foundation

public struct TimeZoneSearchResult: Identifiable, Equatable {
    public var id: String { identifier }
    public let identifier: String
    public let label: String
    public let subtitle: String

    public init(identifier: String, label: String, subtitle: String) {
        self.identifier = identifier
        self.label = label
        self.subtitle = subtitle
    }
}

public struct TimeZoneSearch {
    private let identifiers: [String]
    private let formatter: ClockFormatter

    public init(
        identifiers: [String] = TimeZone.knownTimeZoneIdentifiers,
        formatter: ClockFormatter = ClockFormatter()
    ) {
        self.identifiers = identifiers
        self.formatter = formatter
    }

    public func results(matching query: String, limit: Int = 80) -> [TimeZoneSearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let sortedIdentifiers = identifiers.sorted()

        let matchingIdentifiers = sortedIdentifiers.filter { identifier in
            guard let timeZone = TimeZone(identifier: identifier) else {
                return false
            }

            if normalizedQuery.isEmpty {
                return true
            }

            let normalizedIdentifier = identifier.lowercased()
            let normalizedLabel = formatter.cityLabel(for: timeZone).lowercased()
            return normalizedIdentifier.contains(normalizedQuery) || normalizedLabel.contains(normalizedQuery)
        }

        return matchingIdentifiers.prefix(limit).compactMap { identifier in
            guard let timeZone = TimeZone(identifier: identifier) else {
                return nil
            }

            return TimeZoneSearchResult(
                identifier: identifier,
                label: formatter.cityLabel(for: timeZone),
                subtitle: identifier.replacingOccurrences(of: "_", with: " ")
            )
        }
    }
}
