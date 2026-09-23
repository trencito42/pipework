import SwiftUI

/// Clean, memorable, and elegant main menu screen for PIPEWORK.
public struct MainMenuScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    public let onPlay: () -> Void
    public let onLevels: () -> Void
    public let onSettings: () -> Void

    public init(
        onPlay: @escaping () -> Void,
        onLevels: @escaping () -> Void,
        onSettings: @escaping () -> Void
    ) {
        self.onPlay = onPlay
        self.onLevels = onLevels
        self.onSettings = onSettings
    }

    private var hasProgress: Bool {
        persistence.profile.lastPlayedLevelId != nil || persistence.profile.totalLevelsSolved > 0
    }

    private var continueDetail: String? {
        guard let destination = CampaignProgression.continueLocation(profile: persistence.profile) else { return nil }
        return "\(destination.pack.name) · Level \(destination.level.number)"
    }

    private var totalStars: Int {
        persistence.profile.totalStarsEarned
    }

    private var totalCompleted: Int {
        persistence.profile.totalLevelsSolved
    }

    public var body: some View {
        ZStack {
            // Calm, deep charcoal canvas
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top subtle header pill
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(PipeworkTheme.goldStar)
                        Text("\(totalStars) Stars")
                            .font(PipeworkTheme.captionFont(size: 12, weight: .semibold))
                            .foregroundColor(PipeworkTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(PipeworkTheme.bgElevated)
                            .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                    )

                    Spacer()

                    Button(action: {
                        HapticService.shared.buttonTap()
                        onSettings()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PipeworkTheme.textSecondary)
                    }
                    .buttonStyle(PipeworkIconButtonStyle(size: 34))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer(minLength: 20)

                // Hero Visual Motif & Title
                VStack(spacing: 24) {
                    // Minimal Geometric Pipe Loop Graphic
                    ZStack {
                        // Ambient glow
                        Circle()
                            .fill(PipeworkTheme.primaryCyan.opacity(0.12))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)

                        // Outer geometric ring
                        Circle()
                            .stroke(PipeworkTheme.borderSubtle, lineWidth: 2)
                            .frame(width: 100, height: 100)

                        // Connected pipe circuit motif
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: 50))
                            path.addLine(to: CGPoint(x: 50, y: 50))
                            path.addArc(center: CGPoint(x: 50, y: 65), radius: 15, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
                            path.addLine(to: CGPoint(x: 65, y: 80))
                        }
                        .stroke(PipeworkTheme.primaryCyan, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .frame(width: 100, height: 100)

                        Path { path in
                            path.move(to: CGPoint(x: 80, y: 35))
                            path.addLine(to: CGPoint(x: 50, y: 35))
                            path.addArc(center: CGPoint(x: 50, y: 20), radius: 15, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
                        }
                        .stroke(PipeworkTheme.fluidColor(for: .fuel), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .frame(width: 100, height: 100)

                        // Center node
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .shadow(color: PipeworkTheme.primaryCyan, radius: 6)
                    }

                    VStack(spacing: 8) {
                        Text("PIPEWORK")
                            .font(PipeworkTheme.titleFont(size: 34, weight: .heavy))
                            .foregroundColor(PipeworkTheme.textMain)
                            .tracking(3.0)

                        if hasProgress {
                            Text("\(totalCompleted) of 176 levels completed")
                                .font(PipeworkTheme.captionFont(size: 13, weight: .medium))
                                .foregroundColor(PipeworkTheme.textMuted)
                        } else {
                            Text("A connection puzzle game")
                                .font(PipeworkTheme.captionFont(size: 13, weight: .medium))
                                .foregroundColor(PipeworkTheme.textMuted)
                        }
                    }
                }

                Spacer(minLength: 20)

                // Actions Container
                VStack(spacing: 12) {
                    // Primary Play / Continue Button
                    Button(action: {
                        HapticService.shared.buttonTap()
                        onPlay()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(hasProgress ? "Continue" : "Play")
                                    .font(PipeworkTheme.headingFont(size: 17, weight: .bold))
                                if let detail = continueDetail {
                                    Text(detail)
                                        .font(PipeworkTheme.captionFont(size: 11, weight: .semibold))
                                        .opacity(0.8)
                                }
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .opacity(0.7)
                        }
                        .foregroundColor(Color(red: 6/255, green: 22/255, blue: 22/255))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: PipeworkTheme.radiusLarge)
                                .fill(PipeworkTheme.primaryCyan)
                        )
                        .shadow(color: PipeworkTheme.primaryCyan.opacity(0.30), radius: 14, y: 6)
                    }
                    .buttonStyle(TactilePillStyle())

                    // Secondary Navigation Row (Levels & Settings)
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticService.shared.buttonTap()
                            onLevels()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Level Select")
                                    .font(PipeworkTheme.headingFont(size: 15, weight: .semibold))
                            }
                        }
                        .buttonStyle(PipeworkPillButtonStyle(variant: .secondary))

                        Button(action: {
                            HapticService.shared.buttonTap()
                            onSettings()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Settings")
                                    .font(PipeworkTheme.headingFont(size: 15, weight: .semibold))
                            }
                        }
                        .buttonStyle(PipeworkPillButtonStyle(variant: .subtle))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}

private struct TactilePillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
