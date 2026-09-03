import CoreGraphics

/// Cosmetic recolor for the human player's (team A) boules — purely visual,
/// applied as a tint over the same metallic gradient/shading used for every
/// ball, so customization never affects gameplay.
enum BallAccent: String, CaseIterable, Identifiable {
    case silver
    case orange
    case blue
    case red

    var id: String { rawValue }

    var tint: (CGFloat, CGFloat, CGFloat)? {
        switch self {
        case .silver: return nil
        case .orange: return (0.98, 0.51, 0.10)
        case .blue: return (0.20, 0.55, 0.95)
        case .red: return (0.86, 0.20, 0.20)
        }
    }
}
