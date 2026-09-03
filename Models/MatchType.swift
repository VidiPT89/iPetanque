import Foundation

/// Who controls each side of the match.
enum MatchType: String, CaseIterable, Identifiable {
    case vsCPU
    case localTwoPlayer
    case freeTraining

    var id: String { rawValue }

    var titleKey: L10nKey {
        switch self {
        case .vsCPU: return .matchVsCPU
        case .localTwoPlayer: return .matchLocalTwoPlayer
        case .freeTraining: return .matchFreeTraining
        }
    }

    var icon: String {
        switch self {
        case .vsCPU: return "desktopcomputer"
        case .localTwoPlayer: return "person.2.fill"
        case .freeTraining: return "figure.walk"
        }
    }
}
