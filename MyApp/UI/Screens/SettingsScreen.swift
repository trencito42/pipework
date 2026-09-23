import SwiftUI

/// Modern, cohesive settings screen styled within PIPEWORK's design system.
public struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var persistence = PersistenceService.shared

    @State private var soundEnabled: Bool = true
    @State private var hapticsEnabled: Bool = true
    @State private var colorLabelsEnabled: Bool = false
    @State private var reduceMotionEnabled: Bool = false
    @State private var isShowingResetAlert: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            // Dark base canvas
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Text("Settings")
                        .font(PipeworkTheme.titleFont(size: 20, weight: .bold))
                        .foregroundColor(PipeworkTheme.textMain)

                    Spacer()

                    Button(action: {
                        HapticService.shared.buttonTap()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(PipeworkTheme.headingFont(size: 15, weight: .bold))
                            .foregroundColor(PipeworkTheme.primaryCyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(PipeworkTheme.bgElevated)
                                    .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Audio & Feedback Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AUDIO & FEEDBACK")
                                .font(PipeworkTheme.captionFont(size: 11, weight: .bold))
                                .foregroundColor(PipeworkTheme.textMuted)
                                .tracking(1.0)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                toggleRow(
                                    icon: "speaker.wave.2.fill",
                                    title: "Sound Effects",
                                    subtitle: "Subtle fluid and interaction audio",
                                    isOn: $soundEnabled
                                ) { val in
                                    persistence.updateSettings(sound: val)
                                }

                                Divider()
                                    .background(PipeworkTheme.borderSubtle)
                                    .padding(.leading, 44)

                                toggleRow(
                                    icon: "iphone.radiowaves.left.and.right",
                                    title: "Haptic Feedback",
                                    subtitle: "Tactile grid and connection clicks",
                                    isOn: $hapticsEnabled
                                ) { val in
                                    persistence.updateSettings(haptics: val)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                                    .fill(PipeworkTheme.bgElevated)
                                    .overlay(RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium).stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                            )
                        }

                        // 2. Accessibility Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACCESSIBILITY")
                                .font(PipeworkTheme.captionFont(size: 11, weight: .bold))
                                .foregroundColor(PipeworkTheme.textMuted)
                                .tracking(1.0)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                toggleRow(
                                    icon: "tag.fill",
                                    title: "Color Labels",
                                    subtitle: "Display glyph codes on matching terminals",
                                    isOn: $colorLabelsEnabled
                                ) { val in
                                    persistence.updateSettings(accessibility: val)
                                }

                                Divider()
                                    .background(PipeworkTheme.borderSubtle)
                                    .padding(.leading, 44)

                                toggleRow(
                                    icon: "figure.walk.motion",
                                    title: "Reduce Motion",
                                    subtitle: "Disable fluid pulse animations",
                                    isOn: $reduceMotionEnabled
                                ) { val in
                                    persistence.updateSettings(reduceMotion: val)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                                    .fill(PipeworkTheme.bgElevated)
                                    .overlay(RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium).stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                            )
                        }

                        // 3. Danger Zone / Reset
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PROGRESSION")
                                .font(PipeworkTheme.captionFont(size: 11, weight: .bold))
                                .foregroundColor(PipeworkTheme.textMuted)
                                .tracking(1.0)
                                .padding(.horizontal, 4)

                            Button(action: {
                                HapticService.shared.buttonTap()
                                isShowingResetAlert = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(PipeworkTheme.warningRed)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reset All Progress")
                                            .font(PipeworkTheme.headingFont(size: 15, weight: .semibold))
                                            .foregroundColor(PipeworkTheme.warningRed)
                                        Text("Clear all completed levels and scores")
                                            .font(PipeworkTheme.captionFont(size: 12, weight: .regular))
                                            .foregroundColor(PipeworkTheme.textMuted)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium)
                                        .fill(PipeworkTheme.bgElevated)
                                        .overlay(RoundedRectangle(cornerRadius: PipeworkTheme.radiusMedium).stroke(PipeworkTheme.warningRed.opacity(0.2), lineWidth: 1))
                                )
                            }
                        }

                        // App Version Footnote
                        Text("PIPEWORK · Version 1.2.0")
                            .font(PipeworkTheme.captionFont(size: 11, weight: .medium))
                            .foregroundColor(PipeworkTheme.textDim)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Reset Progress", isPresented: $isShowingResetAlert) {
            Button("Cancel", role: .cancel) {
                HapticService.shared.buttonTap()
            }
            Button("Reset", role: .destructive) {
                HapticService.shared.restart()
                persistence.resetProgress()
                soundEnabled = persistence.profile.soundEnabled
                hapticsEnabled = persistence.profile.hapticsEnabled
                colorLabelsEnabled = persistence.profile.accessibilitySymbolsEnabled
                reduceMotionEnabled = persistence.profile.reduceMotionEnabled
            }
        } message: {
            Text("Are you sure you want to reset all completed levels and scores? This cannot be undone.")
        }
        .onAppear {
            soundEnabled = persistence.profile.soundEnabled
            hapticsEnabled = persistence.profile.hapticsEnabled
            colorLabelsEnabled = persistence.profile.accessibilitySymbolsEnabled
            reduceMotionEnabled = persistence.profile.reduceMotionEnabled
        }
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(PipeworkTheme.primaryCyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PipeworkTheme.headingFont(size: 15, weight: .semibold))
                    .foregroundColor(PipeworkTheme.textMain)
                Text(subtitle)
                    .font(PipeworkTheme.captionFont(size: 12, weight: .regular))
                    .foregroundColor(PipeworkTheme.textMuted)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(PipeworkTheme.primaryCyan)
                .onChange(of: isOn.wrappedValue) { _, val in
                    HapticService.shared.buttonTap()
                    onChange(val)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
