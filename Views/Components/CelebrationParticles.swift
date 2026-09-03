import SwiftUI

struct CelebrationParticles: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let xStart: CGFloat
        let delay: Double
        let color: Color
        let size: CGFloat
    }

    private let particles: [Particle] = (0..<40).map { i in
        Particle(
            xStart: CGFloat.random(in: 0...1),
            delay: Double.random(in: 0...0.6),
            color: [Color("PrimaryOrange"), Color("BurntYellow"), .white].randomElement()!,
            size: CGFloat.random(in: 5...10)
        )
    }

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .position(x: p.xStart * geo.size.width, y: animate ? geo.size.height + 20 : -20)
                        .animation(
                            .easeIn(duration: Double.random(in: 1.6...2.6)).delay(p.delay).repeatForever(autoreverses: false),
                            value: animate
                        )
                }
            }
        }
        .onAppear { animate = true }
        .allowsHitTesting(false)
    }
}
