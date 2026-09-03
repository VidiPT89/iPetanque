import CoreGraphics
import Foundation

struct Ball: Identifiable, Equatable {
    let id = UUID()
    let team: Team
    var position: CGPoint
    var isThrown: Bool = false

    /// Distance to the cochonnet, used for scoring and highlighting.
    func distance(to cochonnet: CGPoint) -> CGFloat {
        hypot(position.x - cochonnet.x, position.y - cochonnet.y)
    }
}
