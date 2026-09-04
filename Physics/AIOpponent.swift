import CoreGraphics

/// Computes where the AI's boule should land: it aims at the cochonnet
/// (or, opportunistically, at the human's leading boule) and adds scatter
/// inversely proportional to the configured difficulty's accuracy.
enum AIOpponent {
    static func chooseTarget(
        cochonnet: CGPoint,
        opponentClosestBall: CGPoint?,
        difficulty: Difficulty,
        fieldSize: CGSize
    ) -> CGPoint {
        // Hard AI occasionally goes for a "shot" on the opponent's best boule
        // instead of just approaching the cochonnet.
        let aimAtOpponent = difficulty == .hard && opponentClosestBall != nil && Bool.random(probability: 0.35)
        let aim = aimAtOpponent ? opponentClosestBall! : cochonnet

        // A floor on scatter keeps consecutive throws (especially at high
        // accuracy) from landing near-identically — with almost no scatter,
        // 2-3 overlapping boules get shoved into an unnaturally tidy,
        // perfectly touching row by the physics engine's passive overlap
        // resolution, which reads as a bug rather than a good AI throw.
        let maxScatter = max(fieldSize.width * (1.0 - difficulty.accuracy) * 0.35, 20)
        let scatterX = CGFloat.random(in: -maxScatter...maxScatter)
        let scatterY = CGFloat.random(in: -maxScatter...maxScatter)

        var target = CGPoint(x: aim.x + scatterX, y: aim.y + scatterY)
        target.x = min(max(target.x, fieldSize.width * 0.08), fieldSize.width * 0.92)
        target.y = min(max(target.y, fieldSize.height * 0.08), fieldSize.height * 0.78)
        return target
    }
}

private extension Bool {
    static func random(probability: Double) -> Bool {
        Double.random(in: 0...1) < probability
    }
}
