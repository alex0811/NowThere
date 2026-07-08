import Foundation

public enum InterfaceLanguage: String, CaseIterable, Identifiable, Equatable, Sendable {
    case system
    case english
    case simplifiedChinese
    case japanese

    public var id: String {
        rawValue
    }
}
