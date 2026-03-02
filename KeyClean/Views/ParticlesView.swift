import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let delay: Double
    let duration: Double
    let size: CGFloat
    let opacity: Double
}

struct ParticlesView: View {
    let count: Int

    @State private var particles: [Particle] = []
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x * geo.size.width,
                            y: animate
                                ? -20
                                : geo.size.height + 20
                        )
                        .animation(
                            .linear(duration: particle.duration)
                            .delay(particle.delay)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
            }
        }
        .onAppear {
            particles = (0..<count).map { _ in
                Particle(
                    x: CGFloat.random(in: 0...1),
                    delay: Double.random(in: 0...8),
                    duration: Double.random(in: 12...28),
                    size: CGFloat.random(in: 1...2.5),
                    opacity: Double.random(in: 0.08...0.25)
                )
            }
            // Trigger animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}
