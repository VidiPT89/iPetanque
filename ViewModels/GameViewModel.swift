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
    @Published var measurement: String?

    weak var scene: PetancaScene?
    var soundManager: SoundManager?

    /// Kept in sync with the SKView's real bounds (see `PetancaFieldView`) so
    /// throw targets, AI aim and on-screen drag coordinates all agree on the
    /// same coordinate space. The initial value is only a placeholder used
    /// for the very first frame before layout happens.
    var fieldSize = CGSize(width: 340, height: 760)
    @Published var targetScore = 13

    /// A throw past this normalized power (0...1, see `humanThrow(toward:power:)`)
    /// is treated as a "shot" (tirer) instead of a soft "point" throw: on
    /// landing it knocks any ball within `shotImpactRadius` away, mirroring
    /// the two throw styles from official petanque instead of a full rigid
    /// body physics simulation.
    private let shotPowerThreshold: CGFloat = 0.62
    private let shotImpactRadius: CGFloat = 30
    private var shotBallIDs: Set<UUID> = []

    private var ballsThrown: [Team: Int] = [.teamA: 0, .teamB: 0]
    private var measurementWorkItem: DispatchWorkItem?

    private enum Move {
        case cochonnet
        case ball(id: UUID, team: Team)
    }
    private var history: [Move] = []

    var canUndo: Bool {
        !history.isEmpty && (phase == .throwBall || phase == .throwCochonnet)
    }

    var ballsRemaining: Int { mode.playersPerTeam * mode.ballsPerPlayer }

    func startNewGame(mode: GameMode, difficulty: Difficulty, targetScore: Int) {
        self.mode = mode
        self.difficulty = difficulty
        self.targetScore = targetScore
        teamAScore = 0
        teamBScore = 0
        winner = nil
        startingTeam = Bool.random() ? .teamA : .teamB
        prepareEnd(starter: startingTeam, phase: .coinToss)
    }

    private func prepareEnd(starter: Team, phase newPhase: GamePhase) {
        scene?.clearBoard()
        balls = []
        cochonnet = nil
        ballsThrown = [.teamA: 0, .teamB: 0]
        currentTeam = starter
        phase = newPhase
        history = []
        measurement = nil
        shotBallIDs.removeAll()
    }

    func confirmCoinToss() {
        phase = .throwCochonnet
        triggerAITurnIfNeeded()
    }

    // MARK: - Throw entry points

    /// Human-initiated throw from a drag gesture. `aim` is already clamped
    /// to the field's coordinate space by the caller. `power` is the drag
    /// distance normalized 0...1 (see `GameView`) — a long, fast pull past
    /// `shotPowerThreshold` throws a "shot" instead of a soft "point".
    func humanThrow(toward aim: CGPoint, power: CGFloat) {
        guard currentTeam.isHuman else { return }
        soundManager?.haptic(power > shotPowerThreshold ? .heavy : .light)
        performThrow(target: aim, isShot: power > shotPowerThreshold)
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
                    }
                target = AIOpponent.chooseTarget(
                    cochonnet: self.cochonnet?.position ?? CGPoint(x: self.fieldSize.width / 2, y: self.fieldSize.height * 0.7),
                    opponentClosestBall: opponentClosest?.position,
                    difficulty: self.difficulty,
                    fieldSize: self.fieldSize
                )
                // A shot at the opponent's boule only reads as intentional
                // when the AI actually aimed close to it.
                aiIsShootingNext = opponentClosest != nil
                    && hypot(target.x - opponentClosest!.position.x, target.y - opponentClosest!.position.y) < self.shotImpactRadius * 2
            }
            let isShot = self.phase == .throwBall && self.aiIsShootingNext
            self.aiIsShootingNext = false
            self.performThrow(target: target, isShot: isShot)
        }
    }

    private var aiIsShootingNext = false

    private func performThrow(target: CGPoint, isShot: Bool) {
        guard let scene else { return }
        soundManager?.playThrow()
        measurement = nil

        if phase == .throwCochonnet {
            history.append(.cochonnet)
            scene.throwCochonnet(to: target)
            return
        }

        let ball = Ball(team: currentTeam, position: .zero)
        history.append(.ball(id: ball.id, team: currentTeam))
        if isShot { shotBallIDs.insert(ball.id) }
        balls.append(ball)
        _ = scene.addBallStart(id: ball.id, team: currentTeam)
        // Let the scene lay out the start frame before animating.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            scene.throwBall(id: ball.id, to: target, isShot: isShot)
        }
    }

    // MARK: - Undo & measure

    func undoLastMove() {
        guard canUndo, let last = history.popLast() else { return }
        switch last {
        case .cochonnet:
            cochonnet = nil
            phase = .throwCochonnet
            scene?.removeCochonnet()
        case .ball(let id, let team):
            balls.removeAll { $0.id == id }
            ballsThrown[team, default: 0] -= 1
            currentTeam = team
            phase = .throwBall
            scene?.removeBall(id: id)
        }
        measurement = nil
        soundManager?.haptic(.rigid)
    }

    func measureClosest() {
        guard let cochonnet, let closest = balls.filter({ $0.isThrown }).min(by: { $0.distance(to: cochonnet.position) < $1.distance(to: cochonnet.position) }) else {
            measurement = nil
            return
        }
        // Cosmetic conversion: the play area maps to roughly a 10m throwing
        // stretch, so distances read as plausible on-field measurements.
        let metersPerPoint = 10.0 / Double(fieldSize.height * 0.85)
        let meters = Double(closest.distance(to: cochonnet.position)) * metersPerPoint
        measurement = String(format: "%.2f m", meters)
        measurementWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.measurement = nil }
        measurementWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }

    // MARK: - Scene callbacks

    func cochonnetDidLand(at point: CGPoint) {
        cochonnet = Cochonnet(position: point)
        phase = .throwBall
        triggerAITurnIfNeeded()
    }

    func ballDidLand(id: UUID, at point: CGPoint) {
        guard let index = balls.firstIndex(where: { $0.id == id }) else { return }
        balls[index].position = point
        balls[index].isThrown = true
        ballsThrown[balls[index].team, default: 0] += 1

        let wasShot = shotBallIDs.remove(id) != nil
        if wasShot {
            applyShotImpact(at: point, excluding: id)
        } else if isNearAnotherBall(point, excluding: id) {
            soundManager?.playCollision()
        }

        advanceTurn()
    }

    private func isNearAnotherBall(_ point: CGPoint, excluding id: UUID) -> Bool {
        balls.contains { other in
            other.id != id && other.isThrown && hypot(other.position.x - point.x, other.position.y - point.y) < 22
        }
    }

    /// A "shot" (tirer) throw: any boule — or the cochonnet itself — caught
    /// within `shotImpactRadius` of the landing point gets knocked further
    /// away along the same line, instead of just sitting where it lands
    /// like a soft "point" throw. This is a lightweight stand-in for real
    /// rigid-body collision physics, keeping landing positions (and so
    /// scoring) fully deterministic.
    private func applyShotImpact(at landingPoint: CGPoint, excluding id: UUID) {
        var hitAnything = false
        let pushDistance: CGFloat = 42

        func pushed(_ position: CGPoint) -> CGPoint {
            let dx = position.x - landingPoint.x
            let dy = position.y - landingPoint.y
            let distance = max(hypot(dx, dy), 1)
            let x = position.x + dx / distance * pushDistance
            let y = position.y + dy / distance * pushDistance
            return CGPoint(
                x: min(max(x, fieldSize.width * 0.06), fieldSize.width * 0.94),
                y: min(max(y, fieldSize.height * 0.06), fieldSize.height * 0.9)
            )
        }

        for index in balls.indices {
            guard balls[index].id != id, balls[index].isThrown else { continue }
            guard balls[index].distance(to: landingPoint) < shotImpactRadius else { continue }
            let newPosition = pushed(balls[index].position)
            balls[index].position = newPosition
            scene?.knockBall(id: balls[index].id, to: newPosition)
            hitAnything = true
        }

        if let cochonnet, cochonnet.distance(to: landingPoint) < shotImpactRadius {
            let newPosition = pushed(cochonnet.position)
            self.cochonnet = Cochonnet(position: newPosition)
            scene?.knockCochonnet(to: newPosition)
            hitAnything = true
        }

        if hitAnything {
            soundManager?.playCollision()
            soundManager?.haptic(.heavy)
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
        prepareEnd(starter: nextStarter, phase: .throwCochonnet)
        triggerAITurnIfNeeded()
    }
}
