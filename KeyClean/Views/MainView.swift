import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showContent = false
    @State private var isHoveringButton = false
    @State private var isPressedButton = false
    @State private var breatheAnimation = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.03, green: 0.03, blue: 0.07)
                .ignoresSafeArea()

            // Ambient glows
            ambientBackground

            // Particles
            ParticlesView(count: 14)

            // Main content — центрируем и не даём растягиваться
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // ── Top section: icon + text ───────────────────────────
                VStack(spacing: 0) {
                    appIcon
                        .padding(.bottom, 22)

                    Text("KeyClean")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Lock your keyboard & trackpad\nto safely clean your MacBook")
                        .font(.system(size: 13.5, weight: .regular))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 16)
                .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1), value: showContent)

                // ── Permission badge ───────────────────────────────────
                permissionBadge
                    .padding(.top, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2), value: showContent)

                // ── Start button ───────────────────────────────────────
                startButton
                    .padding(.top, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.3), value: showContent)

                // ── Feature row — фиксированная высота, не растягивается
                featureRow
                    .padding(.top, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 16)
                    .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.4), value: showContent)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 44)
        }
        .onAppear {
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                breatheAnimation = true
            }
        }
    }

    // MARK: - App Icon

    private var appIcon: some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.5),
                            Color(red: 0.48, green: 0.28, blue: 0.88).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 18)
                .offset(y: 6)

            // Icon background
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.18, blue: 0.38),
                            Color(red: 0.10, green: 0.10, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Keyboard icon — placeholder до загрузки реального логотипа
            Image(systemName: "keyboard")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.72, blue: 1.0),
                            Color(red: 0.55, green: 0.45, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.39, green: 0.40, blue: 0.95)
                                    .opacity(breatheAnimation ? 0.14 : 0.07),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.15)
                    .blur(radius: 90)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.58, green: 0.33, blue: 0.88)
                                    .opacity(breatheAnimation ? 0.11 : 0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.35
                        )
                    )
                    .frame(width: geo.size.width * 0.7)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.85)
                    .blur(radius: 80)
            }
            .animation(
                .easeInOut(duration: 4).repeatForever(autoreverses: true),
                value: breatheAnimation
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Permission Badge

    private var permissionBadge: some View {
        Button(action: {
            if !appState.hasPermission {
                appState.requestPermissions()
            }
        }) {
            HStack(spacing: 8) {
                ZStack {
                    if !appState.hasPermission {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.3))
                            .frame(width: 14, height: 14)
                            .scaleEffect(breatheAnimation ? 2.2 : 1.0)
                            .opacity(breatheAnimation ? 0 : 0.6)
                            .animation(
                                .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                                value: breatheAnimation
                            )
                    }
                    Circle()
                        .fill(
                            appState.hasPermission
                                ? Color(red: 0.2, green: 0.85, blue: 0.5)
                                : Color(red: 1.0, green: 0.6, blue: 0.2)
                        )
                        .frame(width: 6, height: 6)
                }

                Text(
                    appState.hasPermission
                        ? "Accessibility granted"
                        : "Tap to grant Accessibility access"
                )
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(
                    appState.hasPermission
                        ? .white.opacity(0.35)
                        : Color(red: 1.0, green: 0.75, blue: 0.35)
                )
                .fixedSize()

                if !appState.hasPermission {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.35).opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(appState.hasPermission ? 0.04 : 0.06))
                    .overlay(
                        Capsule()
                            .stroke(
                                appState.hasPermission
                                    ? Color.white.opacity(0.07)
                                    : Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.22),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(appState.hasPermission)
        .animation(.easeInOut(duration: 0.5), value: appState.hasPermission)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressedButton = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressedButton = false
                }
                appState.startCleaning()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                Text("Start Cleaning Mode")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 44)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.39, green: 0.40, blue: 0.95),
                                    Color(red: 0.48, green: 0.36, blue: 0.93)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    if isHoveringButton {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.08))
                    }
                }
            )
            .shadow(
                color: Color(red: 0.39, green: 0.40, blue: 0.95)
                    .opacity(isHoveringButton ? 0.55 : 0.28),
                radius: isHoveringButton ? 24 : 14,
                y: 6
            )
            .scaleEffect(isPressedButton ? 0.96 : (isHoveringButton ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHoveringButton = hovering
            }
        }
    }

    // MARK: - Feature Row

    private var featureRow: some View {
        HStack(alignment: .top, spacing: 10) {
            CompactFeatureCard(
                icon: "shield.checkered",
                title: "Full Protection",
                description: "Blocks all input at system level"
            )
            CompactFeatureCard(
                icon: "hand.tap.fill",
                title: "Easy Exit",
                description: "Hold both ⌘ keys for 3 sec"
            )
            CompactFeatureCard(
                icon: "sparkles",
                title: "Clean Safely",
                description: "No accidental input"
            )
        }
    }
}

// MARK: - Compact Feature Card

struct CompactFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.97))
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.80))
                    .fixedSize()

                Text(description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.28))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        // ← Ключевое исправление: убрали maxHeight: .infinity
        // Карточка занимает ровно столько высоты, сколько нужно контенту
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isHovering ? 0.055 : 0.028))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isHovering ? 0.09 : 0.05), lineWidth: 1)
                )
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.18), value: isHovering)
        .onHover { isHovering = $0 }
    }
}
