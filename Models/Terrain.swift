import CoreGraphics

/// Ground surfaces affect how a landed boule rolls/skids and how bouncy a
/// "shot" collision feels — grass absorbs energy, gravel lets things slide.
enum Terrain: String, Codable, CaseIterable, Identifiable {
    case grass
    case hardDirt
    case gravel

    var id: String { rawValue }

    var titleKey: L10nKey {
        switch self {
        case .grass: return .terrainGrass
        case .hardDirt: return .terrainHardDirt
        case .gravel: return .terrainGravel
        }
    }

    var icon: String {
        switch self {
        case .grass: return "leaf.fill"
        case .hardDirt: return "square.stack.3d.up.fill"
        case .gravel: return "circle.grid.3x3.fill"
        }
    }

    /// Physics friction applied to landed boules — higher settles faster.
    var friction: CGFloat {
        switch self {
        case .grass: return 0.75
        case .hardDirt: return 0.45
        case .gravel: return 0.25
        }
    }

    /// Physics restitution (bounciness) on collision.
    var restitution: CGFloat {
        switch self {
        case .grass: return 0.2
        case .hardDirt: return 0.35
        case .gravel: return 0.5
        }
    }

    /// Base ground tint, blended into the procedural texture.
    var baseColor: (top: (CGFloat, CGFloat, CGFloat), bottom: (CGFloat, CGFloat, CGFloat)) {
        switch self {
        case .grass: return ((0.16, 0.32, 0.14), (0.10, 0.22, 0.09))
        case .hardDirt: return ((0.36, 0.27, 0.17), (0.27, 0.19, 0.11))
        case .gravel: return ((0.32, 0.31, 0.29), (0.22, 0.21, 0.20))
        }
    }
}
