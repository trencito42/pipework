import SwiftUI

/// Clean, minimal title and navigation hub for PIPEWORK.
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
        persistence.profile.totalLevelsSolved > 0
    }

    public var body: some View {
        ZStack {
            // Near-black background with very subtle ambient cyan lighting
            RadialGradient(
                colors: [Color(red: 9/255, green: 18/255, blue: 24/255), PipeworkTheme.bgBase],
                center: .init(x: 0.5, y: 0.38),
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero Title
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(PipeworkTheme.primaryCyan)
                            .frame(width: 10, height: 10)
                            .shadow(color: PipeworkTheme.primaryCyan, radius: 8)

                        Text("PIPEWORK")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(PipeworkTheme.textMain)
                            .tracking(4.0)
                    }

                    Text("A connection puzzle game")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(PipeworkTheme.textMuted)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 14) {
                    // Play / Continue Button
                    Button(action: {
                        HapticService.shared.buttonTap()
                        onPlay()
                    }) {
                        Text(hasProgress ? "Continue" : "Play")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(red: 6/255, green: 22/255, blue: 22/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 40/255, green: 245/255, blue: 245/255), Color(red: 20/255, green: 185/255, blue: 185/255)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .shadow(color: PipeworkTheme.primaryCyan.opacity(0.35), radius: 12, y: 4)
                    }

                    // Levels Button
                    Button(action: {
                        HapticService.shared.buttonTap()
                        onLevels()
                    }) {
                        Text("Levels")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PipeworkTheme.textMain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(PipeworkTheme.panelBase)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(PipeworkTheme.borderDim, lineWidth: 1)
                                    )
                            )
                    }

                    // Settings Button
                    Button(action: {
                        HapticService.shared.buttonTap()
                        onSettings()
                    }) {
                        Text("Settings")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PipeworkTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(PipeworkTheme.borderDim.opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
    }
}
