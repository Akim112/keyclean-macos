import SwiftUI

struct ExitProgressView: View {
    let progress: Double
    var size: CGFloat = 140

    private var ringSize: CGFloat { size }
    private let lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            // Background ring (always visible, very subtle)
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)

            // Progress ring
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.51, green: 0.51, blue: 0.96),
                                Color(red: 0.58, green: 0.33, blue: 0.88),
                                Color(red: 0.51, green: 0.51, blue: 0.96)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: progress)

                // Glow effect
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        Color(red: 0.51, green: 0.51, blue: 0.96).opacity(0.4),
                        style: StrokeStyle(lineWidth: lineWidth + 6, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .animation(.linear(duration: 0.05), value: progress)
            }

            // Decorative outer ring (slow rotation)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.clear,
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        center: .center
                    ),
                    lineWidth: 1
                )
                .frame(width: ringSize + 24, height: ringSize + 24)
                .rotationEffect(.degrees(progress * 360))
        }
    }
}
