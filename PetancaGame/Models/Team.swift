import Foundation

enum Team: String, Codable, CaseIterable {
    case teamA
    case teamB

    var isHuman: Bool { self == .teamA }

    var nameKey: L10nKey {
        switch self {
        case .teamA: return .teamA
        case .teamB: return .teamB
        }
    }

    var opponent: Team { self == .teamA ? .teamB : .teamA }
}
