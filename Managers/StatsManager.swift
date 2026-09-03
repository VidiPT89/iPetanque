import Foundation

enum AchievementID: String, CaseIterable, Identifiable {
    case firstWin
    case shutout
    case streak5
    case sharpshooter
    case carreau

    var id: String { rawValue }

    var titleKey: L10nKey {
        switch self {
        case .firstWin: return .achievementFirstWin
        case .shutout: return .achievementShutout
        case .streak5: return .achievementStreak5
        case .sharpshooter: return .achievementSharpshooter
        case .carreau: return .achievementCarreau
        }
    }

    var descriptionKey: L10nKey {
        switch self {
        case .firstWin: return .achievementFirstWinDesc
        case .shutout: return .achievementShutoutDesc
        case .streak5: return .achievementStreak5Desc
        case .sharpshooter: return .achievementSharpshooterDesc
        case .carreau: return .achievementCarreauDesc
        }
    }

    var icon: String {
        switch self {
        case .firstWin: return "star.fill"
        case .shutout: return "shield.fill"
        case .streak5: return "flame.fill"
        case .sharpshooter: return "scope"
        case .carreau: return "target"
        }
    }
}

/// Tracks lightweight lifetime stats and unlockable achievements in
/// `UserDefaults`. Everything here is read/written for real by the game
/// (`GameViewModel`) — no toggle or screen here promises something that
/// doesn't actually happen, matching the lesson learned earlier in this
/// project about "phantom" UI.
final class StatsManager: ObservableObject {
    @Published private(set) var gamesPlayed: Int
    @Published private(set) var gamesWon: Int
    @Published private(set) var currentStreak: Int
    @Published private(set) var shotsTaken: Int
    @Published private(set) var successfulShots: Int
    @Published private(set) var pointsTaken: Int
    @Published private(set) var unlocked: Set<AchievementID>
    @Published var justUnlocked: AchievementID?

    private let defaults = UserDefaults.standard
    private enum Key {
        static let gamesPlayed = "stats.gamesPlayed"
        static let gamesWon = "stats.gamesWon"
        static let currentStreak = "stats.currentStreak"
        static let shotsTaken = "stats.shotsTaken"
        static let successfulShots = "stats.successfulShots"
        static let pointsTaken = "stats.pointsTaken"
        static let unlocked = "stats.unlockedAchievements"
    }

    init() {
        gamesPlayed = defaults.integer(forKey: Key.gamesPlayed)
        gamesWon = defaults.integer(forKey: Key.gamesWon)
        currentStreak = defaults.integer(forKey: Key.currentStreak)
        shotsTaken = defaults.integer(forKey: Key.shotsTaken)
        successfulShots = defaults.integer(forKey: Key.successfulShots)
        pointsTaken = defaults.integer(forKey: Key.pointsTaken)
        let stored = defaults.stringArray(forKey: Key.unlocked) ?? []
        unlocked = Set(stored.compactMap(AchievementID.init(rawValue:)))
    }

    var winRatePercent: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(gamesWon) / Double(gamesPlayed) * 100).rounded())
    }

    /// A throw was made — recorded regardless of whether it hit anything,
    /// so "Sharpshooter" only counts genuinely successful shots.
    func recordThrow(isShot: Bool, hitSomething: Bool) {
        if isShot {
            shotsTaken += 1
            defaults.set(shotsTaken, forKey: Key.shotsTaken)
            if hitSomething {
                successfulShots += 1
                defaults.set(successfulShots, forKey: Key.successfulShots)
                if successfulShots >= 10 { unlock(.sharpshooter) }
            }
        } else {
            pointsTaken += 1
            defaults.set(pointsTaken, forKey: Key.pointsTaken)
        }
    }

    /// A shot landed within `carreauDistance` of the cochonnet — the rare,
    /// celebrated "perfect carreau".
    func recordCarreau() {
        unlock(.carreau)
    }

    func recordGameEnded(won: Bool, finalScore: Int, opponentScore: Int) {
        gamesPlayed += 1
        defaults.set(gamesPlayed, forKey: Key.gamesPlayed)

        if won {
            gamesWon += 1
            currentStreak += 1
            defaults.set(gamesWon, forKey: Key.gamesWon)
            defaults.set(currentStreak, forKey: Key.currentStreak)
            unlock(.firstWin)
            if opponentScore == 0 { unlock(.shutout) }
            if currentStreak >= 5 { unlock(.streak5) }
        } else {
            currentStreak = 0
            defaults.set(currentStreak, forKey: Key.currentStreak)
        }
    }

    func resetAll() {
        gamesPlayed = 0
        gamesWon = 0
        currentStreak = 0
        shotsTaken = 0
        successfulShots = 0
        pointsTaken = 0
        unlocked = []
        for key in [Key.gamesPlayed, Key.gamesWon, Key.currentStreak, Key.shotsTaken, Key.successfulShots, Key.pointsTaken, Key.unlocked] {
            defaults.removeObject(forKey: key)
        }
    }

    private func unlock(_ id: AchievementID) {
        guard !unlocked.contains(id) else { return }
        unlocked.insert(id)
        defaults.set(unlocked.map(\.rawValue), forKey: Key.unlocked)
        justUnlocked = id
    }
}
