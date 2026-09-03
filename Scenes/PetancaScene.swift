import SpriteKit

private enum PhysicsCategory {
    static let ball: UInt32 = 1 << 0
    static let cochonnet: UInt32 = 1 << 1
    static let wall: UInt32 = 1 << 2
}

/// Renders the petanque field and animates throws. The initial flight of a
/// thrown boule is always a deterministic `SKAction` arc to the target the
/// view model computed (so landing positions — and scoring — never depend
/// on physics timing). Real `SKPhysicsBody` collisions only kick in
/// afterwards, for "shot" (tirer) throws: once the shooter boule arrives,
/// it gets a real impulse and can elastically knock already-landed boules
/// (which all carry a resting physics body) out of the way, exactly like
/// official petanque's two throw styles.
final class PetancaScene: SKScene {
    var onBallLanded: ((UUID, CGPoint) -> Void)?
    var onCochonnetLanded: ((CGPoint) -> Void)?
    /// Fired once a "shot" throw's physics has settled, with the *actual*
    /// final position of every ball still on the board plus the cochonnet
    /// (if present) — the view model reconciles its own model against this,
    /// since a real collision can move boules the shooter never directly
    /// aimed at.
    var onBoardSettled: (([UUID: CGPoint], CGPoint?) -> Void)?

    var terrain: Terrain = .hardDirt
    var ballAccent: BallAccent = .silver

    private var ballNodes: [UUID: SKNode] = [:]
    private var cochonnetNode: SKNode?
    private let circleMarker = SKShapeNode(circleOfRadius: 18)

    /// Tracked independently from `size`: with `scaleMode = .resizeFill`,
    /// SpriteKit silently mutates `size` on its own render loop whenever the
    /// view's bounds change, ahead of our own `syncField` call. Comparing
    /// against `size` directly made the "did the size change?" guard below
    /// go stale — SpriteKit would already have "caught up" to the new size
    /// by the time we checked, so the guard saw no change and skipped
    /// re-laying out the field, leaving the ground texture and throwing
    /// circle positioned for whatever tiny frame the view had before
    /// SwiftUI finished its first real layout pass.
    private var lastLayoutSize: CGSize = .zero

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.22, green: 0.16, blue: 0.10, alpha: 1.0)
        scaleMode = .resizeFill
        physicsWorld.gravity = .zero
    }

    private func setupField() {
        guard size.width > 0, size.height > 0 else { return }

        let ground = SKSpriteNode(texture: SKTexture(image: PetancaTextures.groundTexture(size: size, terrain: terrain)))
        ground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ground.size = size
        ground.zPosition = -10
        addChild(ground)

        // Court boundary, inset slightly from the screen edges, echoing the
        // real 4m x 15m rectangle. Also a real physics wall, so a hard shot
        // can't send a boule flying off past the visible field.
        let inset: CGFloat = 14
        let courtRect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
        let court = SKShapeNode(rect: courtRect, cornerRadius: 6)
        court.position = .zero
        court.strokeColor = SKColor.white.withAlphaComponent(0.14)
        court.lineWidth = 1.5
        court.fillColor = .clear
        court.zPosition = -8
        court.physicsBody = SKPhysicsBody(edgeLoopFrom: courtRect)
        court.physicsBody?.categoryBitMask = PhysicsCategory.wall
        court.physicsBody?.friction = 0.3
        addChild(court)

        circleMarker.position = CGPoint(x: size.width / 2, y: size.height * 0.08)
        circleMarker.strokeColor = SKColor(red: 1, green: 0.42, blue: 0.21, alpha: 0.85)
        circleMarker.lineWidth = 3
        circleMarker.fillColor = .clear
        circleMarker.glowWidth = 3
        circleMarker.zPosition = 1
        addChild(circleMarker)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9),
        ])
        circleMarker.setScale(1.0)
        circleMarker.run(SKAction.repeatForever(pulse))
    }

    func syncField(size newSize: CGSize) {
        guard newSize.width > 0, newSize.height > 0, newSize != lastLayoutSize else { return }
        lastLayoutSize = newSize
        size = newSize
        removeAllChildren()
        ballNodes.removeAll()
        cochonnetNode = nil
        setupField()
    }

    // MARK: - Cochonnet

    func throwCochonnet(to target: CGPoint) {
        let node = SKSpriteNode(texture: SKTexture(image: PetancaTextures.cochonnetTexture()))
        node.size = CGSize(width: 16, height: 16)
        node.zPosition = 5
        node.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        node.setScale(0.4)
        node.alpha = 0
        addChild(node)
        cochonnetNode = node

        let glow = SKShapeNode(circleOfRadius: 12)
        glow.fillColor = SKColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 0.35)
        glow.strokeColor = .clear
        glow.zPosition = -1
        glow.blendMode = .add
        node.addChild(glow)

        animateThrow(node: node, to: target, isShot: false, curve: 0) { [weak self] in
            self?.spawnDust(at: target, tint: SKColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 0.5))
            self?.attachPhysics(to: node, category: PhysicsCategory.cochonnet, radius: 6, mass: 0.35)
            self?.onCochonnetLanded?(target)
        }
    }

    func removeCochonnet() {
        cochonnetNode?.removeFromParent()
        cochonnetNode = nil
    }

    /// Removes every thrown ball and the cochonnet, without touching the
    /// static ground/court/circle layout. Must be called whenever the view
    /// model starts a new end (`prepareEnd`) — otherwise every previous
    /// end's boules stay on screen forever, piling up across the whole
    /// match.
    func clearBoard() {
        for node in ballNodes.values {
            node.removeFromParent()
        }
        ballNodes.removeAll()
        removeCochonnet()
    }

    // MARK: - Balls

    func addBallStart(id: UUID, team: Team) -> CGPoint {
        let startX = team == .teamA ? size.width * 0.28 : size.width * 0.72
        let start = CGPoint(x: startX, y: size.height * 0.06)
        let node = makeBallNode(team: team)
        node.position = start
        node.setScale(0.4)
        node.alpha = 0
        node.zPosition = 4
        addChild(node)
        ballNodes[id] = node
        return start
    }

    /// `impulseMagnitude` only matters when `isShot` is true — it scales
    /// the real physics impulse applied on arrival, so a harder pull (or a
    /// tougher AI) genuinely knocks boules further, not just cosmetically.
    func throwBall(id: UUID, to target: CGPoint, isShot: Bool, impulseMagnitude: CGFloat, curve: CGFloat) {
        guard let node = ballNodes[id] else { return }
        let origin = node.position
        animateThrow(node: node, to: target, isShot: isShot, curve: curve) { [weak self] in
            guard let self else { return }
            self.spawnDust(at: target, tint: SKColor.white.withAlphaComponent(0.4))
            self.attachPhysics(to: node, category: PhysicsCategory.ball, radius: 9, mass: 1.0)

            if isShot {
                self.shake()
                let dx = target.x - origin.x
                let dy = target.y - origin.y
                let length = max(hypot(dx, dy), 1)
                let impulse = CGVector(dx: dx / length * impulseMagnitude, dy: dy / length * impulseMagnitude)
                node.physicsBody?.applyImpulse(impulse)
                self.scheduleSettleReport()
            } else {
                // The new resting `physicsBody` can overlap an already-landed
                // boule sitting almost exactly at `target` (e.g. two AI
                // throws both aiming at the cochonnet with little scatter)
                // — SpriteKit's passive collision resolution nudges them
                // apart on the very next physics step, purely from the
                // world simulation, with no impulse involved. Waiting one
                // short tick and reporting the node's *actual* settled
                // position (instead of blindly trusting `target`) keeps the
                // model in sync with what the player actually sees, instead
                // of scoring/AI logic silently working off a stale point.
                self.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.12),
                    SKAction.run { [weak self, weak node] in
                        guard let node else { return }
                        self?.onBallLanded?(id, node.position)
                    },
                ]))
            }
        }
    }

    func removeBall(id: UUID) {
        ballNodes[id]?.removeFromParent()
        ballNodes[id] = nil
    }

    /// Gives a landed node a real, resting physics body so a *later* shot
    /// can collide with it elastically. Zero initial velocity means it just
    /// sits exactly where the deterministic throw animation left it — no
    /// visual difference from before for a plain "point" throw.
    private func attachPhysics(to node: SKNode, category: UInt32, radius: CGFloat, mass: CGFloat) {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.categoryBitMask = category
        body.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.cochonnet | PhysicsCategory.wall
        body.contactTestBitMask = 0
        body.mass = mass
        body.friction = terrain.friction
        body.restitution = terrain.restitution
        body.linearDamping = 4.5
        body.angularDamping = 4.5
        body.allowsRotation = true
        body.affectedByGravity = false
        node.physicsBody = body
    }

    /// After a shot's impulse, wait for the physics simulation to settle
    /// (high damping means it's essentially still well within this window)
    /// then report every ball's — and the cochonnet's — *actual* final
    /// position, since a real collision can move boules the shooter never
    /// directly targeted.
    private func scheduleSettleReport() {
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.run { [weak self] in
                guard let self else { return }
                var positions: [UUID: CGPoint] = [:]
                for (id, node) in self.ballNodes {
                    positions[id] = node.position
                }
                self.onBoardSettled?(positions, self.cochonnetNode?.position)
            },
        ]))
    }

    private func shake() {
        let amount: CGFloat = 6
        let shake = SKAction.sequence([
            SKAction.moveBy(x: amount, y: 0, duration: 0.03),
            SKAction.moveBy(x: -amount * 2, y: 0, duration: 0.05),
            SKAction.moveBy(x: amount, y: 0, duration: 0.03),
        ])
        run(shake)
    }

    private func makeBallNode(team: Team) -> SKNode {
        let container = SKNode()
        let accent = team == .teamA ? ballAccent : .silver
        let sprite = SKSpriteNode(texture: SKTexture(image: PetancaTextures.ballTexture(team: team, accent: accent)))
        sprite.size = CGSize(width: 22, height: 22)
        container.addChild(sprite)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 17, height: 5))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.28)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -11)
        shadow.zPosition = -1
        container.addChild(shadow)

        return container
    }

    private func animateThrow(node: SKNode, to target: CGPoint, isShot: Bool, curve: CGFloat, completion: @escaping () -> Void) {
        let origin = node.position
        let distance = hypot(target.x - origin.x, target.y - origin.y)
        // A "shot" (tirer) is a flat, fast, direct throw — official petanque
        // describes it as landing with little to no roll, unlike the high,
        // gentle arc of a "point" throw. Shorter duration and a much
        // smaller arc bump sell that difference without new assets.
        let baseDuration = min(1.1, max(0.45, TimeInterval(distance) / 420.0))
        let duration = isShot ? baseDuration * 0.55 : baseDuration
        let arcPeak: CGFloat = isShot ? 1.08 : 1.35

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15),
        ])

        // A gentle "lift" via a scale bump partway through sells an arc
        // without needing a true 3D trajectory.
        let riseScale = SKAction.scale(to: arcPeak, duration: duration * 0.45)
        riseScale.timingMode = .easeOut
        let fallScale = SKAction.scale(to: 1.0, duration: duration * 0.55)
        fallScale.timingMode = .easeIn
        let arcScale = SKAction.sequence([riseScale, fallScale])

        let move: SKAction
        // "Effect": bend the path through an offset midpoint instead of a
        // straight line, when the player flicked sideways at release.
        // Shots stay flat/direct on purpose (see `humanThrow`, which never
        // passes a nonzero curve for a shot).
        if abs(curve) > 0.06, distance > 1 {
            let dx = target.x - origin.x
            let dy = target.y - origin.y
            let perpendicular = CGVector(dx: -dy / distance, dy: dx / distance)
            let bend = distance * 0.22 * curve
            let midpoint = CGPoint(
                x: origin.x + dx * 0.5 + perpendicular.dx * bend,
                y: origin.y + dy * 0.5 + perpendicular.dy * bend
            )
            let toMidpoint = SKAction.move(to: midpoint, duration: duration * 0.5)
            toMidpoint.timingMode = .easeOut
            let toTarget = SKAction.move(to: target, duration: duration * 0.5)
            toTarget.timingMode = .easeIn
            move = SKAction.sequence([toMidpoint, toTarget])
        } else {
            let straight = SKAction.move(to: target, duration: duration)
            straight.timingMode = isShot ? .linear : .easeOut
            move = straight
        }

        let spin = SKAction.rotate(byAngle: .pi * (isShot ? 6 : 4), duration: duration)

        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.08),
            SKAction.scale(to: 0.96, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08),
        ])

        let throwGroup = SKAction.group([move, spin, arcScale])
        let sequence = SKAction.sequence([appear, throwGroup, bounce, SKAction.run(completion)])
        node.run(sequence)
    }

    private func spawnDust(at point: CGPoint, tint: SKColor) {
        for _ in 0..<7 {
            let speck = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            speck.fillColor = tint
            speck.strokeColor = .clear
            speck.position = point
            speck.zPosition = 3
            addChild(speck)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let travel = CGFloat.random(in: 10...26)
            let dx = cos(angle) * travel
            let dy = sin(angle) * travel * 0.5 + 6

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([move, fade])
            speck.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }
}
