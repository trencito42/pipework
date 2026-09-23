import SwiftUI

/// Title and game hub screen presenting industrial visual fiction and mode selection.
public struct MainMenuScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    public let onPlayCampaign: () -> Void
    public let onPlayInfinite: () -> Void
    public let onOpenSettings: () -> Void

    public init(
        onPlayCampaign: @escaping () -> Void,
        onPlayInfinite: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.onPlayCampaign = onPlayCampaign
        self.onPlayInfinite = onPlayInfinite
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ZStack {
            // Dark industrial background with radial gradient
            RadialGradient(
                colors: [PipeworkTheme.bgVignette, PipeworkTheme.bgBase],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 20,
                endRadius: 550
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                // Studio Branding
                HStack(spacing: 6) {
                    Circle()
                        .fill(PipeworkTheme.primaryCyan)
                        .frame(width: 6, height: 6)
                    Text("BLIPMADE")
                        .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .tracking(3.0)
                }
                .padding(.top, 24)

                Spacer()

                // Hero Logo & Subtitle
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(PipeworkTheme.primaryCyan)
                            .frame(width: 10, height: 10)
                            .shadow(color: PipeworkTheme.primaryCyan, radius: 8)

                        Text("PIPEWORK")
                            .font(PipeworkTheme.roundedFont(size: 38, weight: .heavy))
                            .foregroundColor(PipeworkTheme.textMain)
                            .tracking(4.0)
                            .shadow(color: PipeworkTheme.primaryCyan.opacity(0.3), radius: 15)
                    }

                    Text("INDUSTRIAL FLUID ROUTING SYSTEM")
                        .font(PipeworkTheme.monoFont(size: 11, weight: .semibold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .tracking(1.8)
                }

                // Global Telemetry Card
                HStack(spacing: 16) {
                    telemetryMetric(title: "RESTORED", value: "\(persistence.profile.totalLevelsSolved)")
                    Divider()
                        .frame(height: 28)
                        .background(PipeworkTheme.borderDim)
                    telemetryMetric(title: "ROUTED", value: "\(persistence.profile.totalPipesRouted)")
                    Divider()
                        .frame(height: 28)
                        .background(PipeworkTheme.borderDim)
                    telemetryMetric(title: "INTEGRITY", value: "100%")
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(PipeworkTheme.panelBase)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(PipeworkTheme.borderDim, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // Tactical Menu Actions
                VStack(spacing: 14) {
                    // Campaign Button (Primary Glowing)
                    Button(action: onPlayCampaign) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("SECTOR MATRIX")
                                .font(PipeworkTheme.monoFont(size: 15, weight: .bold))
                                .tracking(1.8)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color(red: 5/255, green: 22/255, blue: 22/255))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 36/255, green: 240/255, blue: 240/255), Color(red: 21/255, green: 184/255, blue: 184/255)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(color: PipeworkTheme.primaryCyan.opacity(0.35), radius: 10, y: 3)
                    }

                    // Procedural Infinite Generator
                    Button(action: onPlayInfinite) {
                        HStack(spacing: 10) {
                            Image(systemName: "infinity")
                                .font(.system(size: 15, weight: .bold))
                            Text("PROCEDURAL OVERDRIVE")
                                .font(PipeworkTheme.monoFont(size: 14, weight: .bold))
                                .tracking(1.4)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(PipeworkTheme.textMain)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(PipeworkTheme.panelBase)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(PipeworkTheme.borderDim, lineWidth: 1)
                                )
                        )
                    }

                    // Settings & Diagnostics Button
                    Button(action: onOpenSettings) {
                        HStack(spacing: 10) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("SYSTEM CONFIG & TELEMETRY")
                                .font(PipeworkTheme.monoFont(size: 13, weight: .semibold))
                                .tracking(1.2)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(PipeworkTheme.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(PipeworkTheme.borderDim.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func telemetryMetric(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                .foregroundColor(PipeworkTheme.textMuted)
            Text(value)
                .font(PipeworkTheme.roundedFont(size: 18, weight: .heavy))
                .foregroundColor(PipeworkTheme.primaryCyan)
        }
        .frame(maxWidth: .infinity)
    }
}
