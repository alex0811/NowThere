import Foundation

public enum TimeFormat: String, CaseIterable, Identifiable, Equatable, Sendable {
    case twentyFourHour
    case twelveHour

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .twentyFourHour:
            "24-hour"
        case .twelveHour:
            "12-hour"
        }
    }

    public var dateFormat: String {
        switch self {
        case .twentyFourHour:
            "HH:mm"
        case .twelveHour:
            "h:mm a"
        }
    }
}
