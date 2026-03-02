import SwiftUI

struct CleaningView: View {
    @EnvironmentObject var appState: AppState
    @State private var showContent = false
    @State private var lockBobbing = false
    @State private var elapsedSeconds: Int = 0
    @State private var clockTimer: Timer? = nil
    @State private var breatheAnimation = false

    private let accentColor = Color(red: 0.39, green: 0.40, blue: 0.95)
    private let accentLight = Color(red: 0.51, green: 0.51, blue: 0.96)
    private var bothPressed: Bool { appState.leftCmdPressed && appState.rightCmdPressed }

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 560

            ZStack {
                // Background
                Color(red: 0.03, green: 0.03, blue: 0.06)
                    .ignoresSafeArea()

                // Ambient glow
                ambientGlow(size: geo.size)

                // Particles
                ParticlesView(count: 14)

                // Main content
                VStack(spacing: 0) {
                    Spacer()

                    // Status badge
                    statusBadge()
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: showContent)

                    Spacer().frame(height: isCompact ? 40 : 60)

                    // Lock icon + progress ring
                    lockSection(isCompact: isCompact)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.85)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2), value: showContent)

                    Spacer().frame(height: isCompact ? 40 : 60)

                    // Timer or exit progress text
                    timerSection(isCompact: isCompact)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: showContent)

                    Spacer().frame(height: isCompact ? 40 : 64)

                    // Exit hint + key indicators
                    exitSection(isCompact: isCompact)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)

                    Spacer()
                }
                .padding(.horizontal, isCompact ? 32 : 48)
            }
        }
        .onAppear {
            showContent = true
            startClock()
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                lockBobbing = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breatheAnimation = true
            }
        }
        .onDisappear {
            stopClock()
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private func statusBadge() -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(red: 0.2, green: 0.85, blue: 0.45))
                .frame(width: 7, height: 7)
                .shadow(color: Color(red: 0.2, green: 0.85, blue: 0.45).opacity(0.7), radius: 5)

            Text("Cleaning Mode Active")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Lock Section

    @ViewBuilder
    private func lockSection(isCompact: Bool) -> some View {
        let ringSize: CGFloat = isCompact ? 140 : 180
        let iconSize: CGFloat = isCompact ? 44 : 56

        ZStack {
            // Outer decorative ring
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                .frame(width: ringSize + 40, height: ringSize + 40)

            // Progress ring
            ExitProgressView(
                progress: appState.exitProgress,
                size: ringSize
            )

            // Inner circle bg
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: ringSize - 30, height: ringSize - 30)

            // Lock icon
            Image(systemName: bothPressed ? "lock.open.fill" : "lock.fill")
                .font(.system(size: iconSize, weight: .light))
                .foregroundColor(bothPressed ? accentLight : .white.opacity(0.85))
                .offset(y: lockBobbing ? -6 : 0)
                .animation(
                    bothPressed ? .none : .easeInOut(duration: 3.5).repeatForever(autoreverses: true),
                    value: lockBobbing
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bothPressed)
        }
    }

    // MARK: - Timer Section

    @ViewBuilder
    private func timerSection(isCompact: Bool) -> some View {
        VStack(spacing: 8) {
            if bothPressed && appState.exitProgress > 0 {
                // Show exit percent
                Text("\(Int(appState.exitProgress * 100))%")
                    .font(.system(size: isCompact ? 42 : 52, weight: .thin, design: .monospaced))
                    .foregroundColor(accentLight)
                    .contentTransition(.numericText())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))

                Text("releasing...")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(accentColor.opacity(0.7))
                    .transition(.opacity)
            } else {
                // Show cleaning timer
                Text(formatTime(elapsedSeconds))
                    .font(.system(size: isCompact ? 42 : 52, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .contentTransition(.numericText())
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))

                Text("cleaning time")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.25))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: bothPressed)
    }

    // MARK: - Exit Section

    @ViewBuilder
    private func exitSection(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 20 : 28) {
            // Hint text
            Text(bothPressed ? "Keep holding to exit..." : "Hold both ⌘ keys for 3 seconds to exit")
                .font(.system(size: isCompact ? 13 : 14, weight: .regular))
                .foregroundColor(.white.opacity(bothPressed ? 0.55 : 0.25))
                .animation(.easeOut(duration: 0.3), value: bothPressed)

            // Key indicators
            HStack(spacing: isCompact ? 14 : 20) {
                KeyIndicator(label: "⌘ Left", isPressed: appState.leftCmdPressed)
                KeyIndicator(label: "⌘ Right", isPressed: appState.rightCmdPressed)
            }
        }
    }

    // MARK: - Ambient Glow

    @ViewBuilder
    private func ambientGlow(size: CGSize) -> some View {
        ZStack {
            // Top-left glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(breatheAnimation ? 0.09 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.4
                    )
                )
                .frame(width: size.width * 0.8, height: size.width * 0.8)
                .position(x: size.width * 0.1, y: size.height * 0.2)
                .blur(radius: 100)

            // Bottom-right glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.58, green: 0.33, blue: 0.88).opacity(breatheAnimation ? 0.07 : 0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.35
                    )
                )
                .frame(width: size.width * 0.6, height: size.width * 0.6)
                .position(x: size.width * 0.9, y: size.height * 0.85)
                .blur(radius: 90)

            // Center glow when holding
            if bothPressed {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.3
                        )
                    )
                    .frame(width: size.width * 0.6, height: size.width * 0.6)
                    .position(x: size.width * 0.5, y: size.height * 0.45)
                    .blur(radius: 80)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: bothPressed)
    }

    // MARK: - Helpers

    private func startClock() {
        elapsedSeconds = 0
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopClock() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Key Indicator

struct KeyIndicator: View {
    let label: String
    let isPressed: Bool

    private let accentColor = Color(red: 0.39, green: 0.40, blue: 0.95)
    private let accentLight = Color(red: 0.51, green: 0.51, blue: 0.96)

    var body: some View {
        Text(label)
            .font(.system(size: 15, weight: .medium, design: .monospaced))
            .foregroundColor(isPressed ? accentLight : .white.opacity(0.28))
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isPressed ? accentColor.opacity(0.15) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isPressed ? accentLight.opacity(0.45) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isPressed ? accentColor.opacity(0.35) : .clear,
                radius: 16
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }
}
