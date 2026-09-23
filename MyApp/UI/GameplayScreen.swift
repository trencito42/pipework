import SwiftUI

/// Main native gameplay screen for PIPEWORK.
public struct GameplayScreen: View {
    @State private var packs: [LevelPack] = LevelRepository.allPacks
    @State private var packIndex: Int = 2 // Default to 7x7 Sector Pack
    @State private var levelIndex: Int = 0

    @State private var puzzleState: PuzzleState
    @State private var history = MoveHistory()
    @State private var showSymbols: Bool = false
    @State private var isVictoryPresented: Bool = false
    @State private var toastMessage: String? = nil
    @State private var toastWorkItem: DispatchWorkItem? = nil
    @State private var blockedCoord: GridCoord? = nil
    @State private var isSoundOn: Bool = true

    public init() {
        let initialLevel = LevelRepository.sector7x7Pack.levels[0]
        _puzzleState = State(initialValue: initialLevel.createInitialState())
    }

    private var currentPack: LevelPack {
        packs[packIndex]
    }

    private var currentLevel: LevelDefinition {
        currentPack.levels[levelIndex]
    }

    public var body: some View {
        ZStack {
            // Dark graphite environment with subtle radial vignette
            RadialGradient(
                colors: [PipeworkTheme.bgVignette, PipeworkTheme.bgBase],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // 1. Brand & Header Zone
                headerZone

                // 2. 3-Column Status Bar with Integrated Pressure Meter
                StatusPanel(
                    connectedLines: puzzleState.connectedLineCount,
                    totalLines: puzzleState.totalLineCount,
                    moves: puzzleState.moveCount,
                    pressurePercentage: puzzleState.pressurePercentage
                )
                .padding(.horizontal, 16)

                // 3. Hero Board Container with Diagnostic Toast
                ZStack {
                    BoardCanvasView(
                        state: $puzzleState,
                        history: $history,
                        showAccessibilitySymbols: showSymbols,
                        blockedCoord: blockedCoord,
                        onBlockedCoordHandled: { blockedCoord = nil }
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(.horizontal, 16)

                    // Diagnostic Toast Message
                    if let toast = toastMessage {
                        VStack {
                            Spacer()
                            Text(toast)
                                .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 124/255, green: 141/255, blue: 159/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(red: 13/255, green: 17/255, blue: 23/255))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(red: 33/255, green: 42/255, blue: 54/255), lineWidth: 1)
                                        )
                                )
                                .offset(y: 32)
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // 4. Bottom Controls Zone (Undo, Hint, Restart)
                controlsZone
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Victory Modal
            if isVictoryPresented {
                VictoryOverlayView(
                    sectorName: currentPack.name,
                    moves: puzzleState.moveCount,
                    connectedFluids: puzzleState.connectedLineCount,
                    totalFluids: puzzleState.totalLineCount,
                    onNextSector: loadNextSector
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .onChange(of: puzzleState.isSolved) { _, isSolved in
            if isSolved {
                withAnimation(.spring(duration: 0.4)) {
                    isVictoryPresented = true
                }
            }
        }
    }

    // MARK: - Header Zone

    private var headerZone: some View {
        HStack {
            // Brand Title with Status Dot
            HStack(spacing: 8) {
                Circle()
                    .fill(PipeworkTheme.primaryCyan)
                    .frame(width: 6, height: 6)
                    .shadow(color: PipeworkTheme.primaryCyan, radius: 4)

                Text("PIPEWORK")
                    .font(PipeworkTheme.roundedFont(size: 20, weight: .heavy))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(2.5)
            }

            Spacer()

            // Sound Toggle & Sector Display Badge
            HStack(spacing: 8) {
                Button(action: toggleSound) {
                    Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSoundOn ? PipeworkTheme.textMuted : PipeworkTheme.textDim)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.04))
                        )
                }

                Text(currentPack.name)
                    .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 109/255, green: 125/255, blue: 145/255))
                    .tracking(1.4)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 15/255, green: 19/255, blue: 24/255))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(red: 28/255, green: 34/255, blue: 44/255), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Tactical Controls Zone

    private var controlsZone: some View {
        HStack(spacing: 24) {
            // Undo Button
            tacticalRoundButton(
                iconName: "arrow.uturn.backward",
                disabled: !history.canUndo,
                action: undoAction
            )

            // Engineering Hint Button
            tacticalRoundButton(
                iconName: "scope",
                disabled: isVictoryPresented,
                action: provideHintAction
            )

            // Flush / Restart Button
            tacticalRoundButton(
                iconName: "arrow.triangle.2.circlepath",
                disabled: false,
                action: restartSectorAction
            )
        }
    }

    private func tacticalRoundButton(
        iconName: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                // Inset Outer Ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 22/255, green: 28/255, blue: 36/255), Color(red: 13/255, green: 17/255, blue: 22/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 35/255, green: 44/255, blue: 56/255), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 6, y: 3)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(disabled ? PipeworkTheme.textDim : Color(red: 131/255, green: 146/255, blue: 165/255))
            }
        }
        .disabled(disabled)
        .buttonStyle(TactileButtonStyle())
    }

    // MARK: - Actions

    private func toggleSound() {
        isSoundOn.toggle()
        AudioService.shared.isEnabled = isSoundOn
        HapticService.shared.terminalTouchDown()
    }

    private func undoAction() {
        if let previous = history.undo(currentState: puzzleState) {
            puzzleState = previous
            AudioService.shared.playRouteCut()
            HapticService.shared.lineCut()
        }
    }

    private func provideHintAction() {
        guard !puzzleState.isSolved else { return }

        // Find a pair whose current path does not match canonical solution
        guard let canonical = currentLevel.canonicalSolution else { return }

        var targetDef: CanonicalPathDefinition? = nil
        for pathDef in canonical {
            let currentPath = puzzleState.paths[pathDef.lineId]
            if currentPath == nil || currentPath?.coordinates != pathDef.path {
                targetDef = pathDef
                break
            }
        }

        guard let target = targetDef else { return }

        // Remove conflicting lines
        let solSet = Set(target.path)
        for (lineId, path) in puzzleState.paths {
            if lineId != target.lineId && path.coordinates.contains(where: { solSet.contains($0) }) {
                var cleared = path
                cleared.clear()
                puzzleState.updatePath(for: lineId, path: cleared)
            }
        }

        // Apply canonical path
        if var path = puzzleState.paths[target.lineId] {
            path.clear()
            for (idx, coord) in target.path.enumerated() {
                if idx == 0 {
                    path.start(at: coord)
                } else {
                    path.append(coord)
                }
            }
            puzzleState.updatePath(for: target.lineId, path: path)
            puzzleState.moveCount += 1
            AudioService.shared.playConnectionLocked()
            HapticService.shared.lineConnected()
            showToast("OPTIMIZED: \(target.lineId.uppercased())")
        }
    }

    private func restartSectorAction() {
        puzzleState = currentLevel.createInitialState()
        history.clear()
        isVictoryPresented = false
        AudioService.shared.playRouteCut()
        HapticService.shared.lineCut()
        showToast("SYSTEM PURGED")
    }

    private func loadNextSector() {
        if levelIndex + 1 < currentPack.levels.count {
            levelIndex += 1
        } else if packIndex + 1 < packs.count {
            packIndex += 1
            levelIndex = 0
        } else {
            packIndex = 0
            levelIndex = 0
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            puzzleState = currentLevel.createInitialState()
            history.clear()
            isVictoryPresented = false
        }
    }

    private func showToast(_ text: String) {
        toastWorkItem?.cancel()
        withAnimation(.easeIn(duration: 0.15)) {
            toastMessage = text
        }
        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.25)) {
                toastMessage = nil
            }
        }
        toastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }
}

/// Custom tactile button press style
private struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
