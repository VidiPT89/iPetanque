import UIKit

/// Generates small procedural textures (metallic boules, the cochonnet, the
/// sandy ground) with `UIGraphicsImageRenderer` so the game never needs
/// bundled image assets. Results are cached since the same handful of
/// textures are reused for every ball on the field.
enum PetancaTextures {
    private static var ballCache: [String: UIImage] = [:]
    private static var cochonnetCache: UIImage?
    private static var groundCache: [String: UIImage] = [:]

    static func ballTexture(team: Team, accent: BallAccent = .silver) -> UIImage {
        let cacheKey = "\(team.rawValue)-\(accent.rawValue)"
        if let cached = ballCache[cacheKey] { return cached }

        let size = CGSize(width: 88, height: 88)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            var base: [UIColor]
            switch team {
            case .teamA:
                base = [UIColor(white: 0.92, alpha: 1), UIColor(white: 0.72, alpha: 1), UIColor(white: 0.42, alpha: 1)]
            case .teamB:
                base = [UIColor(red: 0.72, green: 0.50, blue: 0.28, alpha: 1), UIColor(red: 0.50, green: 0.32, blue: 0.16, alpha: 1), UIColor(red: 0.28, green: 0.16, blue: 0.08, alpha: 1)]
            }
            // Only the human player's own boules (team A) can be
            // recolored; blend the accent hue into the metallic gradient
            // rather than replacing it, so the reflections still read.
            if team == .teamA, let tint = accent.tint {
                base = base.map { color in
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    color.getRed(&r, green: &g, blue: &b, alpha: &a)
                    return UIColor(
                        red: r * 0.35 + tint.0 * 0.65,
                        green: g * 0.35 + tint.1 * 0.65,
                        blue: b * 0.35 + tint.2 * 0.65,
                        alpha: a
                    )
                }
            }

            let cg = ctx.cgContext
            cg.saveGState()
            cg.addEllipse(in: rect)
            cg.clip()

            let colors = [base[0].cgColor, base[1].cgColor, base[2].cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1])!
            cg.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.28),
                startRadius: 1,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: rect.width * 0.75,
                options: []
            )

            // Rim shading: a dark crescent opposite the highlight sells the
            // metallic sheen without a full lighting model.
            cg.setFillColor(UIColor.black.withAlphaComponent(0.22).cgColor)
            let rim = UIBezierPath(ovalIn: rect.insetBy(dx: -rect.width * 0.02, dy: -rect.height * 0.02))
            cg.addPath(rim.cgPath)
            cg.fillPath(using: .winding)

            cg.restoreGState()

            // Specular highlight.
            cg.saveGState()
            let highlight = UIBezierPath(ovalIn: CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.14, width: rect.width * 0.28, height: rect.height * 0.18))
            cg.setFillColor(UIColor.white.withAlphaComponent(0.75).cgColor)
            cg.addPath(highlight.cgPath)
            cg.fillPath()
            cg.restoreGState()

            // Fine grooves, characteristic of real boules.
            cg.saveGState()
            cg.addEllipse(in: rect)
            cg.clip()
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.10).cgColor)
            cg.setLineWidth(0.6)
            for i in 0..<5 {
                let r = rect.insetBy(dx: rect.width * 0.08 * CGFloat(i), dy: rect.height * 0.08 * CGFloat(i))
                cg.addEllipse(in: r)
            }
            cg.strokePath()
            cg.restoreGState()

            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.4).cgColor)
            cg.setLineWidth(1)
            cg.strokeEllipse(in: rect)
        }
        ballCache[cacheKey] = image
        return image
    }

    static func cochonnetTexture() -> UIImage {
        if let cached = cochonnetCache { return cached }
        let size = CGSize(width: 44, height: 44)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)
            let cg = ctx.cgContext
            let colors = [
                UIColor(red: 1.0, green: 0.90, blue: 0.55, alpha: 1).cgColor,
                UIColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 1).cgColor,
                UIColor(red: 0.75, green: 0.52, blue: 0.10, alpha: 1).cgColor,
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.5, 1])!
            cg.saveGState()
            cg.addEllipse(in: rect)
            cg.clip()
            cg.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.3),
                startRadius: 1,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: rect.width * 0.75,
                options: []
            )
            cg.restoreGState()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            cg.setLineWidth(1)
            cg.strokeEllipse(in: rect)
        }
        cochonnetCache = image
        return image
    }

    static func groundTexture(size: CGSize, terrain: Terrain = .hardDirt) -> UIImage {
        let key = "\(Int(size.width))x\(Int(size.height))-\(terrain.rawValue)"
        if let cached = groundCache[key] { return cached }

        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let cg = ctx.cgContext

            let top = terrain.baseColor.top
            let bottom = terrain.baseColor.bottom
            let colors = [
                UIColor(red: top.0, green: top.1, blue: top.2, alpha: 1).cgColor,
                UIColor(red: bottom.0, green: bottom.1, blue: bottom.2, alpha: 1).cgColor,
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: rect.height), options: [])

            // Sparse grain speckles for a sandy/earthy read.
            var generator = SeededGenerator(seed: UInt64(size.width * size.height))
            for _ in 0..<Int(size.width * size.height / 900) {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let r = CGFloat.random(in: 0.4...1.3, using: &generator)
                let lighter = Bool.random(using: &generator)
                cg.setFillColor((lighter ? UIColor.white : UIColor.black).withAlphaComponent(0.05).cgColor)
                cg.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
            }

            // Soft vignette to focus attention on the play area.
            let vignetteColors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.35).cgColor] as CFArray
            let vignette = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: vignetteColors, locations: [0, 1])!
            cg.drawRadialGradient(
                vignette,
                startCenter: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: rect.width * 0.35,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: rect.width * 0.95,
                options: [.drawsAfterEndLocation]
            )
        }
        groundCache[key] = image
        return image
    }
}

/// Deterministic RNG so the ground texture is stable across regenerations
/// of the same size (avoids visible "shimmer" if `groundTexture` is ever
/// called twice for the same dimensions before caching kicks in).
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdead_beef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
