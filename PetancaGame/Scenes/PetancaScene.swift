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

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.30, green: 0.22, blue: 0.14, alpha: 1.0)
        scaleMode = .resizeFill
        setupField()
    }

    private func setupField() {
        // Subtle texture using layered translucent lines so the sand/earth
        // feel reads even without an image asset.
        for i in stride(from: 0, to: 20, by: 1) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1.5))
            line.position = CGPoint(x: size.width / 2, y: CGFloat(i) * (size.height / 20))
            line.fillColor = SKColor.black.withAlphaComponent(0.04)
            line.strokeColor = .clear
            line.zPosition = 0
            addChild(line)
        }

        circleMarker.position = CGPoint(x: size.width / 2, y: size.height * 0.08)
        circleMarker.strokeColor = SKColor(red: 1, green: 0.42, blue: 0.21, alpha: 0.9)
        circleMarker.lineWidth = 3
        circleMarker.fillColor = .clear
        circleMarker.zPosition = 1
        addChild(circleMarker)
    }

    func syncField(size newSize: CGSize) {
        guard newSize != size, newSize.width > 0, newSize.height > 0 else { return }
        size = newSize
        removeAllChildren()
        ballNodes.removeAll()
        cochonnetNode = nil
        setupField()
    }

    // MARK: - Cochonnet

    func throwCochonnet(to target: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 7)
        node.fillColor = SKColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 1.0)
        node.strokeColor = SKColor.white.withAlphaComponent(0.6)
        node.lineWidth = 1
        node.zPosition = 5
        node.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        node.setScale(0.4)
        node.alpha = 0
        addChild(node)
        cochonnetNode = node

        animateThrow(node: node, to: target) { [weak self] in
            self?.onCochonnetLanded?(target)
        }
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
            self?.onBallLanded?(id, target)
        }
    }

    private func makeBallNode(team: Team) -> SKNode {
        let container = SKNode()
        let base = SKShapeNode(circleOfRadius: 10)
        base.fillColor = team == .teamA
            ? SKColor(red: 0.85, green: 0.86, blue: 0.88, alpha: 1)
            : SKColor(red: 0.55, green: 0.35, blue: 0.20, alpha: 1)
        base.strokeColor = SKColor.black.withAlphaComponent(0.35)
        base.lineWidth = 0.5
        container.addChild(base)

        let shine = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        shine.fillColor = SKColor.white.withAlphaComponent(0.55)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -3, y: 3)
        container.addChild(shine)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 16, height: 5))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.25)
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

    func settle(to positions: [UUID: CGPoint]) {
        for (id, point) in positions {
            ballNodes[id]?.position = point
        }
    }
}
