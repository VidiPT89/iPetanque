import Combine
import CoreGraphics
import SwiftUI

enum GamePhase {
    case coinToss
    case throwCochonnet
    case throwBall
    case endOfEnd
    case gameOver
}

final class GameViewModel: ObservableObject {
    @Published var mode: GameMode = .singles
    @Published var difficulty: Difficulty = .medium
    @Published var teamAScore = 0
    @Published var teamBScore = 0
    @Published var cochonnet: Cochonnet?
    @Published var balls: [Ball] = []
    @Published var currentTeam: Team = .teamA
    @Published var startingTeam: Team = .teamA
    @Published var phase: GamePhase = .coinToss
    @Published var lastEndWinner: Team?
    @Published var lastEndPoints = 0
    @Published var winner: Team?
    @Published var isAiThinking = false

    weak var scene: PetancaScene?
    var soundManager: SoundManager?

    let fieldSize = CGSize(width: 340, height: 760)
    let targetScore = 13

    private var ballsThrown: [Team: Int] = [.teamA: 0, .teamB: 0]
    private var pendingBallID: UUID?

    var ballsRemaining: Int { mode.playersPerTeam * mode.ballsPerPlayer }

    func startNewGame(mode: GameMode, difficulty: Difficulty) {
        self.mode = mode
        self.difficulty = difficulty
        teamAScore = 0
        teamBScore = 0
        winner = nil
        startingTeam = Bool.random() ? .teamA : .teamB
        phase = .coinToss
        prepareEnd(starter: startingTeam)
    }

    private func prepareEnd(starter: Team) {
        balls = []
        cochonnet = nil
        ballsThrown = [.teamA: 0, .teamB: 0]
        currentTeam = starter
        phase = .throwCochonnet
    }

    func confirmCoinToss() {
        phase = .throwCochonnet
        if currentTeam == .teamB {
            triggerAITurnIfNeeded()
        }
    }

    // MARK: - Throw entry points

    /// Human-initiated throw from a drag gesture. `aim` is already clamped
    /// to the field's coordinate space by the caller.
    func humanThrow(toward aim: CGPoint) {
        guard currentTeam.isHuman else { return }
        performThrow(target: aim)
    }

    private func triggerAITurnIfNeeded() {
        guard !currentTeam.isHuman, phase == .throwCochonnet || phase == .throwBall else { return }
        isAiThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + difficulty.thinkingDelay) { [weak self] in
            guard let self else { return }
            self.isAiThinking = false
            let target: CGPoint
            if self.phase == .throwCochonnet {
                target = CGPoint(x: self.fieldSize.width / 2, y: self.fieldSize.height * CGFloat.random(in: 0.55...0.85))
            } else {
                let opponentClosest = self.balls
                    .filter { $0.team == self.currentTeam.opponent }
                    .min { a, b in
                        guard let c = self.cochonnet?.position else { return false }
                        return a.distance(to: c) < b.distance(to: c)
                    }?.position
                target = AIOpponent.chooseTarget(
                    cochonnet: self.cochonnet?.position ?? CGPoint(x: self.fieldSize.width / 2, y: self.fieldSize.height * 0.7),
                    opponentClosestBall: opponentClosest,
                    difficulty: self.difficulty,
                    fieldSize: self.fieldSize
                )
            }
            self.performThrow(target: target)
        }
    }

    private func performThrow(target: CGPoint) {
        guard let scene else { return }
        soundManager?.playThrow()

        if phase == .throwCochonnet {
            scene.throwCochonnet(to: target)
            return
        }

        let ball = Ball(team: currentTeam, position: .zero)
        pendingBallID = ball.id
        balls.append(ball)
        _ = scene.addBallStart(id: ball.id, team: currentTeam)
        // Let the scene lay out the start frame before animating.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            scene.throwBall(id: ball.id, to: target)
        }
    }

    // MARK: - Scene callbacks

    func cochonnetDidLand(at point: CGPoint) {
        cochonnet = Cochonnet(position: point, isPlaced: true)
        phase = .throwBall
        triggerAITurnIfNeeded()
    }

    func ballDidLand(id: UUID, at point: CGPoint) {
        guard let index = balls.firstIndex(where: { $0.id == id }) else { return }
        balls[index].position = point
        balls[index].isThrown = true
        ballsThrown[balls[index].team, default: 0] += 1

        if isNearAnotherBall(point, excluding: id) {
            soundManager?.playCollision()
        }

        advanceTurn()
    }

    private func isNearAnotherBall(_ point: CGPoint, excluding id: UUID) -> Bool {
        balls.contains { other in
            other.id != id && other.isThrown && hypot(other.position.x - point.x, other.position.y - point.y) < 22
        }
    }

    // MARK: - Turn logic

    private func advanceTurn() {
        let aRemaining = ballsRemaining - (ballsThrown[.teamA] ?? 0)
        let bRemaining = ballsRemaining - (ballsThrown[.teamB] ?? 0)

        if aRemaining <= 0 && bRemaining <= 0 {
            endTheEnd()
            return
        }

        if aRemaining <= 0 {
            currentTeam = .teamB
        } else if bRemaining <= 0 {
            currentTeam = .teamA
        } else if let leader = closestTeam() {
            currentTeam = leader.opponent
        } else {
            currentTeam = currentTeam.opponent
        }

        triggerAITurnIfNeeded()
    }

    private func closestTeam() -> Team? {
        guard let cochonnet, let best = balls.filter({ $0.isThrown }).min(by: { $0.distance(to: cochonnet.position) < $1.distance(to: cochonnet.position) }) else {
            return nil
        }
        return best.team
    }

    // MARK: - Scoring

    private func endTheEnd() {
        guard let cochonnet else { return }
        let sorted = balls.sorted { $0.distance(to: cochonnet.position) < $1.distance(to: cochonnet.position) }
        guard let leadingTeam = sorted.first?.team else { return }

        var points = 0
        for ball in sorted {
            if ball.team == leadingTeam {
                points += 1
            } else {
                break
            }
        }

        if leadingTeam == .teamA {
            teamAScore += points
        } else {
            teamBScore += points
        }

        lastEndWinner = leadingTeam
        lastEndPoints = points
        phase = .endOfEnd

        if teamAScore >= targetScore || teamBScore >= targetScore {
            winner = teamAScore > teamBScore ? .teamA : .teamB
            phase = .gameOver
            soundManager?.playVictory()
        }
    }

    func continueAfterEnd() {
        guard phase != .gameOver else { return }
        let nextStarter = lastEndWinner ?? startingTeam
        prepareEnd(starter: nextStarter)
        if currentTeam == .teamB {
            triggerAITurnIfNeeded()
        }
    }

    func resetGame() {
        teamAScore = 0
        teamBScore = 0
        winner = nil
        phase = .coinToss
    }
}
