import SwiftUI

/// Clean settings screen managing player preferences and progression reset.
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
        NavigationStack {
            ZStack {
                PipeworkTheme.bgBase
                    .ignoresSafeArea()

                List {
                    Section(header: Text("Gameplay").foregroundColor(PipeworkTheme.textMuted)) {
                        Toggle("Sound", isOn: $soundEnabled)
                            .onChange(of: soundEnabled) { _, val in
                                persistence.updateSettings(sound: val)
                            }

                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, val in
                                persistence.updateSettings(haptics: val)
                            }

                        Toggle("Color Labels", isOn: $colorLabelsEnabled)
                            .onChange(of: colorLabelsEnabled) { _, val in
                                persistence.updateSettings(accessibility: val)
                            }

                        Toggle("Reduce Motion", isOn: $reduceMotionEnabled)
                            .onChange(of: reduceMotionEnabled) { _, val in
                                persistence.updateSettings(reduceMotion: val)
                            }
                    }
                    .listRowBackground(PipeworkTheme.panelBase)
                    .foregroundColor(PipeworkTheme.textMain)

                    Section {
                        Button(role: .destructive, action: { isShowingResetAlert = true }) {
                            Text("Reset Progress")
                                .foregroundColor(PipeworkTheme.warningRed)
                        }
                    }
                    .listRowBackground(PipeworkTheme.panelBase)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(PipeworkTheme.primaryCyan)
                }
            }
            .alert("Reset Progress", isPresented: $isShowingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
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
    }
}
