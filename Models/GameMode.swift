import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case singles
    case doubles
    case triples

    var id: String { rawValue }

    var ballsPerPlayer: Int {
        switch self {
        case .singles, .doubles: return 3
        case .triples: return 2
        }
    }

    var playersPerTeam: Int {
        switch self {
        case .singles: return 1
        case .doubles: return 2
        case .triples: return 3
        }
    }

    var titleKey: L10nKey {
        switch self {
        case .singles: return .singles
        case .doubles: return .doubles
        case .triples: return .triples
        }
    }

    var icon: String {
        switch self {
        case .singles: return "person.fill"
        case .doubles: return "person.2.fill"
        case .triples: return "person.3.fill"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy, medium, hard

    var titleKey: L10nKey {
        switch self {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        }
    }

    /// Higher accuracy = AI throws land closer to their intended target.
    var accuracy: Double {
        switch self {
        case .easy: return 0.55
        case .medium: return 0.75
        case .hard: return 0.92
        }
    }

    var thinkingDelay: Double {
        switch self {
        case .easy: return 0.6
        case .medium: return 1.0
        case .hard: return 1.4
        }
    }
}
