import Foundation

public enum TitleStyle: String, CaseIterable, Identifiable, Equatable, Sendable {
    case standard = "default"
    case timeFirst
    case separated
    case bracketed

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .standard:
            "Default"
        case .timeFirst:
            "Time First"
        case .separated:
            "Separated"
        case .bracketed:
            "Bracketed"
        }
    }
}
