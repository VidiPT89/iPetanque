import CoreGraphics

struct Cochonnet {
    var position: CGPoint

    func distance(to point: CGPoint) -> CGFloat {
        hypot(position.x - point.x, position.y - point.y)
    }
}
