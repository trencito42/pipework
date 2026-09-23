import SwiftUI

/// Industrial system diagnostics and accessibility configuration screen.
public struct SettingsScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingResetAlert: Bool = false

    public var body: some View {
        ZStack {
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(PipeworkTheme.primaryCyan)
                            .frame(width: 8, height: 8)
                        Text("DIAGNOSTICS & SYSTEM CONFIG")
                            .font(PipeworkTheme.monoFont(size: 14, weight: .bold))
                            .foregroundColor(PipeworkTheme.textMain)
                            .tracking(1.5)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(PipeworkTheme.textMuted)
                            .padding(8)
                            .background(Circle().fill(PipeworkTheme.panelBase))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Settings Group
                VStack(spacing: 16) {
                    settingToggle(
                        title: "ACOUSTIC FEEDBACK",
                        subtitle: "Synthesized pneumatic & tactile audio FX",
                        isOn: Binding(
                            get: { persistence.profile.soundEnabled },
                            set: { persistence.updateSettings(sound: $0) }
                        )
                    )

                    settingToggle(
                        title: "TACTILE HAPTICS",
                        subtitle: "Taptic engine vibration on pipe traversal",
                        isOn: Binding(
                            get: { persistence.profile.hapticsEnabled },
                            set: { persistence.updateSettings(haptics: $0) }
                        )
                    )

                    settingToggle(
                        title: "ACCESSIBILITY GLYPHS",
                        subtitle: "Display geometric symbols on fluid sockets",
                        isOn: Binding(
                            get: { persistence.profile.accessibilitySymbolsEnabled },
                            set: { persistence.updateSettings(accessibility: $0) }
                        )
                    )

                    settingToggle(
                        title: "REDUCE MOTION",
                        subtitle: "Minimize dynamic fluid wave phase effects",
                        isOn: Binding(
                            get: { persistence.profile.reduceMotionEnabled },
                            set: { persistence.updateSettings(reduceMotion: $0) }
                        )
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PipeworkTheme.panelBase)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(PipeworkTheme.borderDim, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                // Statistics Card
                VStack(spacing: 12) {
                    Text("SYSTEM TELEMETRY")
                        .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        statBox(title: "SECTORS SOLVED", value: "\(persistence.profile.totalLevelsSolved)")
                        statBox(title: "PIPES ROUTED", value: "\(persistence.profile.totalPipesRouted)")
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(PipeworkTheme.panelBase)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(PipeworkTheme.borderDim, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                Spacer()

                // Reset Button
                Button(action: { isShowingResetAlert = true }) {
                    Text("FLUSH ALL SYSTEM RECORDS")
                        .font(PipeworkTheme.monoFont(size: 12, weight: .bold))
                        .foregroundColor(PipeworkTheme.warningRed)
                        .tracking(1.2)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(PipeworkTheme.warningRed.opacity(0.4), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .alert("Flush System Data?", isPresented: $isShowingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                persistence.resetProgress()
            }
        } message: {
            Text("This will permanently clear all saved sector completions, star ratings, and statistics.")
        }
    }

    private func settingToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PipeworkTheme.monoFont(size: 13, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMain)
                Text(subtitle)
                    .font(PipeworkTheme.monoFont(size: 10, weight: .regular))
                    .foregroundColor(PipeworkTheme.textMuted)
            }
        }
        .tint(PipeworkTheme.primaryCyan)
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                .foregroundColor(PipeworkTheme.textMuted)
            Text(value)
                .font(PipeworkTheme.roundedFont(size: 20, weight: .heavy))
                .foregroundColor(PipeworkTheme.primaryCyan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 10/255, green: 13/255, blue: 17/255))
        )
    }
}
