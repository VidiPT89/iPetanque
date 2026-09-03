import SpriteKit

/// Renders the petanque field and animates throws. Landing positions are
/// decided by the view model (so scoring math is deterministic); this scene
/// is purely responsible for making the throw *look* physical: an eased
/// arc, a rolling spin, a soft bounce, a puff of dust and, for the AI, a
/// visible wind-up.
final class PetancaScene: SKScene {
    var onBallLanded: ((UUID, CGPoint) -> Void)?
    var onCochonnetLanded: ((CGPoint) -> Void)?

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
    }

    private func setupField() {
        guard size.width > 0, size.height > 0 else { return }

        let ground = SKSpriteNode(texture: SKTexture(image: PetancaTextures.groundTexture(size: size)))
        ground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ground.size = size
        ground.zPosition = -10
        addChild(ground)

        // Court boundary, inset slightly from the screen edges, echoing the
        // real 4m x 15m rectangle.
        let inset: CGFloat = 14
        let court = SKShapeNode(rectOf: CGSize(width: size.width - inset * 2, height: size.height - inset * 2), cornerRadius: 6)
        court.position = CGPoint(x: size.width / 2, y: size.height / 2)
        court.strokeColor = SKColor.white.withAlphaComponent(0.14)
        court.lineWidth = 1.5
        court.fillColor = .clear
        court.zPosition = -8
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

        animateThrow(node: node, to: target) { [weak self] in
            self?.spawnDust(at: target, tint: SKColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 0.5))
            self?.onCochonnetLanded?(target)
        }
    }

    func removeCochonnet() {
        cochonnetNode?.removeFromParent()
        cochonnetNode = nil
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

    func throwBall(id: UUID, to target: CGPoint) {
        guard let node = ballNodes[id] else { return }
        animateThrow(node: node, to: target) { [weak self] in
            self?.spawnDust(at: target, tint: SKColor.white.withAlphaComponent(0.4))
            self?.onBallLanded?(id, target)
        }
    }

    func removeBall(id: UUID) {
        ballNodes[id]?.removeFromParent()
        ballNodes[id] = nil
    }

    private func makeBallNode(team: Team) -> SKNode {
        let container = SKNode()
        let sprite = SKSpriteNode(texture: SKTexture(image: PetancaTextures.ballTexture(team: team)))
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

    private func animateThrow(node: SKNode, to target: CGPoint, completion: @escaping () -> Void) {
        let distance = hypot(target.x - node.position.x, target.y - node.position.y)
        let duration = min(1.1, max(0.45, TimeInterval(distance) / 420.0))

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15),
        ])

        // A gentle "lift" via a scale bump partway through sells an arc
        // without needing a true 3D trajectory.
        let riseScale = SKAction.scale(to: 1.35, duration: duration * 0.45)
        riseScale.timingMode = .easeOut
        let fallScale = SKAction.scale(to: 1.0, duration: duration * 0.55)
        fallScale.timingMode = .easeIn
        let arcScale = SKAction.sequence([riseScale, fallScale])

        let move = SKAction.move(to: target, duration: duration)
        move.timingMode = .easeOut

        let spin = SKAction.rotate(byAngle: .pi * 4, duration: duration)

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
