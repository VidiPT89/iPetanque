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
    @Published var terrain: Terrain = .hardDirt
    @Published var ballAccent: BallAccent = .silver
    @Published var matchType: MatchType = .vsCPU

    var isFreeTraining: Bool { matchType == .freeTraining }

    /// Whether a human is at the controls for this team right now — always
    /// true for both teams in local 2-player, always team A only otherwise
    /// (vs CPU or free training, where team B never plays at all).
    func isHumanControlled(_ team: Team) -> Bool {
        matchType == .localTwoPlayer ? true : team.isHuman
    }

    private func isAIControlled(_ team: Team) -> Bool {
        matchType == .vsCPU && !team.isHuman
    }

    func remainingBalls(for team: Team) -> Int {
        max(0, ballsRemaining - (ballsThrown[team] ?? 0))
    }

    weak var scene: PetancaScene?
    var soundManager: SoundManager?
    var statsManager: StatsManager?

    /// Kept in sync with the SKView's real bounds (see `PetancaFieldView`) so
    /// throw targets, AI aim and on-screen drag coordinates all agree on the
    /// same coordinate space. The initial value is only a placeholder used
    /// for the very first frame before layout happens.
    var fieldSize = CGSize(width: 340, height: 760)
    @Published var targetScore = 13

    /// How much of the screen, at the top and bottom, is actually covered
    /// by fixed SwiftUI chrome (score/HUD bar, turn indicator/controls) —
    /// measured for real from `GameView` via `GeometryReader`/`PreferenceKey`,
    /// not guessed. Every throw target (human or AI) is clamped to stay
    /// outside these strips, and `PetancaScene` draws the court boundary to
    /// match exactly, so a boule can never land somewhere the player can't
    /// see or reach — see `clampY`.
    ///
    /// Deliberately NOT `@Published`: `GameView` sets these from
    /// `onPreferenceChange`, which fires on every layout pass of the bars
    /// being measured. If this were `@Published`, each assignment would
    /// (even when the value is unchanged — `@Published` doesn't check
    /// equality) trigger `objectWillChange`, re-rendering `GameView`,
    /// re-measuring the same bars, re-firing the same preference, and
    /// re-assigning again — an infinite render loop that saturates the
    /// main thread and starves the AI's `DispatchQueue.main.asyncAfter`
    /// turn timer (confirmed: with this `@Published`, the AI never threw
    /// the cochonnet within a 2-minute test run). Every other place that
    /// needs the current value (`clampY`, `PetancaFieldView.updateUIView`)
    /// already runs on its own trigger, so no UI depends on this being
    /// observable.
    var topSafeInset: CGFloat = 110
    var bottomSafeInset: CGFloat = 150

    /// Clamps a y coordinate (SpriteKit's bottom-up field space) to the
    /// visible, reachable strip between the bottom and top UI chrome.
    func clampY(_ y: CGFloat) -> CGFloat {
        let ballMargin: CGFloat = 16
        let minY = bottomSafeInset + ballMargin
        let maxY = max(minY, fieldSize.height - topSafeInset - ballMargin)
        return min(max(y, minY), maxY)
    }

    /// A throw past this normalized power (0...1, see `humanThrow(toward:power:)`)
    /// is treated as a "shot" (tirer): a real `SKPhysicsBody` impulse is
    /// applied on arrival instead of the boule simply resting where the
    /// deterministic arc animation ends, so it can genuinely — physically —
    /// knock other boules out of the way (see `PetancaScene`).
    private let shotPowerThreshold: CGFloat = 0.62
    private let shotImpactRadius: CGFloat = 30
    private let carreauDistance: CGFloat = 12
    /// Snapshot of every landed boule + the cochonnet right before a shot is
    /// thrown, so `boardDidSettle` can tell whether the shot actually moved
    /// anything (for stats) by comparing before/after.
    private var preShotSnapshot: (balls: [UUID: CGPoint], cochonnet: CGPoint?)?
    private var pendingShotBallID: UUID?

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

    func startNewGame(mode: GameMode, difficulty: Difficulty, targetScore: Int, terrain: Terrain, matchType: MatchType) {
        self.mode = mode
        self.difficulty = difficulty
        self.targetScore = targetScore
        self.terrain = terrain
        self.matchType = matchType
        if let stored = UserDefaults.standard.string(forKey: "ballAccent"), let accent = BallAccent(rawValue: stored) {
            self.ballAccent = accent
        }
        teamAScore = 0
        teamBScore = 0
        winner = nil
        if matchType == .freeTraining {
            // No opponent, no suspense — always the player, straight into
            // the first throw.
            startingTeam = .teamA
            prepareEnd(starter: .teamA, phase: .throwCochonnet)
        } else {
            startingTeam = Bool.random() ? .teamA : .teamB
            prepareEnd(starter: startingTeam, phase: .coinToss)
        }
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
        preShotSnapshot = nil
        pendingShotBallID = nil
    }

    func confirmCoinToss() {
        phase = .throwCochonnet
        triggerAITurnIfNeeded()
    }

    // MARK: - Throw entry points

    /// Human-initiated throw from a drag gesture. `aim` is already clamped
    /// to the field's coordinate space by the caller. `power` is the drag
    /// distance normalized 0...1 (see `GameView`) — a long, fast pull past
    /// `shotPowerThreshold` throws a "shot" instead of a soft "point", and
    /// also scales how hard that shot's physics impulse lands. `curve` is
    /// the sideways "effect" (-1...1) read from lateral movement at
    /// release — only bends "point" throws, matching real petanque where
    /// effect is used to curve around a blocking boule, not on a flat shot.
    func humanThrow(toward aim: CGPoint, power: CGFloat, curve: CGFloat) {
        guard isHumanControlled(currentTeam) else { return }
        let isShot = power > shotPowerThreshold
        soundManager?.haptic(isShot ? .heavy : .light)
        let clamped = CGPoint(x: aim.x, y: clampY(aim.y))
        performThrow(target: clamped, isShot: isShot, impulseMagnitude: 260 + power * 260, curve: isShot ? 0 : curve)
    }

    private func triggerAITurnIfNeeded() {
        guard isAIControlled(currentTeam), phase == .throwCochonnet || phase == .throwBall else { return }
        isAiThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + difficulty.thinkingDelay) { [weak self] in
            guard let self else { return }
            self.isAiThinking = false
            let target: CGPoint
            var isShot = false
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
                isShot = opponentClosest != nil
                    && hypot(target.x - opponentClosest!.position.x, target.y - opponentClosest!.position.y) < self.shotImpactRadius * 2
            }
            let clampedTarget = CGPoint(x: target.x, y: self.clampY(target.y))
            self.performThrow(target: clampedTarget, isShot: isShot, impulseMagnitude: 360 + self.difficulty.accuracy * 120, curve: 0)
        }
    }

    private func performThrow(target: CGPoint, isShot: Bool, impulseMagnitude: CGFloat, curve: CGFloat) {
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
        balls.append(ball)

        if isShot {
            let restingBalls = balls.filter { $0.isThrown }
            preShotSnapshot = (
                balls: Dictionary(uniqueKeysWithValues: restingBalls.map { ($0.id, $0.position) }),
                cochonnet: cochonnet?.position
            )
            pendingShotBallID = ball.id
        }

        _ = scene.addBallStart(id: ball.id, team: currentTeam)
        // Let the scene lay out the start frame before animating.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            scene.throwBall(id: ball.id, to: target, isShot: isShot, impulseMagnitude: impulseMagnitude, curve: curve)
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

    /// Fires for plain "point" throws only — a "shot" throw instead waits
    /// for `boardDidSettle` once its physics impulse has resolved, since a
    /// real collision can move more than just the thrown boule.
    func ballDidLand(id: UUID, at point: CGPoint) {
        guard let index = balls.firstIndex(where: { $0.id == id }) else { return }
        balls[index].position = point
        balls[index].isThrown = true
        ballsThrown[balls[index].team, default: 0] += 1
        statsManager?.recordThrow(isShot: false, hitSomething: false)

        if isNearAnotherBall(point, excluding: id) {
            soundManager?.playCollision()
        }

        advanceTurn()
    }

    /// A "shot" throw's real physics impulse has settled: reconcile the
    /// model's positions against what actually happened on the board (the
    /// shooter boule, plus anything it collided with), then proceed exactly
    /// as a normal landed throw would.
    func boardDidSettle(positions: [UUID: CGPoint], cochonnetPosition: CGPoint?) {
        for index in balls.indices {
            if let position = positions[balls[index].id] {
                balls[index].position = position
            }
        }
        if let cochonnetPosition, cochonnet != nil {
            cochonnet = Cochonnet(position: cochonnetPosition)
        }

        if let shotID = pendingShotBallID, let index = balls.firstIndex(where: { $0.id == shotID }) {
            balls[index].isThrown = true
            ballsThrown[balls[index].team, default: 0] += 1

            let hitSomething = didShotHitAnything(finalPositions: positions, finalCochonnet: cochonnetPosition)
            statsManager?.recordThrow(isShot: true, hitSomething: hitSomething)
            if let cochonnet, cochonnet.distance(to: balls[index].position) < carreauDistance {
                statsManager?.recordCarreau()
            }
            if hitSomething {
                soundManager?.playCollision()
                soundManager?.haptic(.heavy)
            }
        }

        preShotSnapshot = nil
        pendingShotBallID = nil
        advanceTurn()
    }

    private func didShotHitAnything(finalPositions: [UUID: CGPoint], finalCochonnet: CGPoint?) -> Bool {
        guard let snapshot = preShotSnapshot else { return false }
        let movedThreshold: CGFloat = 4

        for (id, before) in snapshot.balls {
            guard id != pendingShotBallID, let after = finalPositions[id] else { continue }
            if hypot(after.x - before.x, after.y - before.y) > movedThreshold { return true }
        }
        if let before = snapshot.cochonnet, let after = finalCochonnet {
            if hypot(after.x - before.x, after.y - before.y) > movedThreshold { return true }
        }
        return false
    }

    private func isNearAnotherBall(_ point: CGPoint, excluding id: UUID) -> Bool {
        balls.contains { other in
            other.id != id && other.isThrown && hypot(other.position.x - point.x, other.position.y - point.y) < 22
        }
    }

    // MARK: - Turn logic

    private func advanceTurn() {
        if isFreeTraining {
            if remainingBalls(for: .teamA) <= 0 {
                endTheEnd()
            } else {
                currentTeam = .teamA
            }
            return
        }

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

        if isFreeTraining {
            lastEndWinner = nil
            lastEndPoints = 0
            phase = .endOfEnd
            return
        }

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
            statsManager?.recordGameEnded(
                won: winner == .teamA,
                finalScore: teamAScore,
                opponentScore: teamBScore
            )
        }
    }

    func continueAfterEnd() {
        guard phase != .gameOver else { return }
        let nextStarter = lastEndWinner ?? startingTeam
        prepareEnd(starter: nextStarter, phase: .throwCochonnet)
        triggerAITurnIfNeeded()
    }
}
