import SwiftUI

/// Main native interactive gameplay screen for PIPEWORK.
@MainActor
public struct GameplayScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared

    public let initialPack: LevelPack
    public let initialLevel: LevelDefinition
    public let onExitToMenu: () -> Void
    public let onOpenLevelSelect: () -> Void

    @State private var currentPack: LevelPack
    @State private var currentLevel: LevelDefinition
    @State private var puzzleState: PuzzleState
    @State private var history = MoveHistory()
    @State private var isVictoryPresented: Bool = false
    @State private var toastMessage: String? = nil
    @State private var toastWorkItem: DispatchWorkItem? = nil
    @State private var isSettingsOpen: Bool = false

    public init(
        pack: LevelPack = LevelRepository.sector7x7Pack,
        level: LevelDefinition = LevelRepository.sector7x7Pack.levels[0],
        onExitToMenu: @escaping () -> Void = {},
        onOpenLevelSelect: @escaping () -> Void = {}
    ) {
        self.initialPack = pack
        self.initialLevel = level
        self.onExitToMenu = onExitToMenu
        self.onOpenLevelSelect = onOpenLevelSelect

        _currentPack = State(initialValue: pack)
        _currentLevel = State(initialValue: level)
        _puzzleState = State(initialValue: level.createInitialState())
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
                // 1. Header Zone
                headerZone

                // 2. 3-Column Status Bar with Integrated Pressure Meter
                StatusPanel(
                    connectedLines: puzzleState.connectedLineCount,
                    totalLines: puzzleState.totalLineCount,
                    moves: puzzleState.moveCount,
                    pressurePercentage: puzzleState.pressurePercentage
                )
                .padding(.horizontal, 16)

                // 3. Hero Board Container with Toast
                ZStack {
                    BoardCanvasView(
                        state: $puzzleState,
                        history: $history,
                        showAccessibilitySymbols: persistence.profile.accessibilitySymbolsEnabled,
                        reduceMotion: persistence.profile.reduceMotionEnabled,
                        onStrokeCommitted: handleStrokeCommitted
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(.horizontal, 16)

                    // Brief Feedback Toast
                    if let toast = toastMessage {
                        VStack {
                            Spacer()
                            Text(toast)
                                .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 140/255, green: 160/255, blue: 180/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 13/255, green: 17/255, blue: 23/255))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(red: 33/255, green: 42/255, blue: 54/255), lineWidth: 1)
                                        )
                                )
                                .offset(y: 32)
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // 4. Bottom Tactical Controls Zone (Undo, Hint, Restart)
                controlsZone
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Victory Modal
            if isVictoryPresented {
                let bestMoves = persistence.getRecord(for: currentLevel.id)?.bestMoves
                VictoryOverlayView(
                    levelTitle: "Level \(currentLevel.number)",
                    moves: puzzleState.moveCount,
                    bestMoves: bestMoves,
                    onNextLevel: loadNextLevel,
                    onReplay: restartLevelAction,
                    onLevels: {
                        HapticService.shared.buttonTap()
                        onOpenLevelSelect()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsScreen()
        }
    }

    // MARK: - Header Zone

    private var headerZone: some View {
        HStack {
            Button(action: {
                HapticService.shared.buttonTap()
                onOpenLevelSelect()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("Levels")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(PipeworkTheme.textMain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PipeworkTheme.panelBase)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PipeworkTheme.borderDim, lineWidth: 1))
                )
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(PipeworkTheme.primaryCyan)
                    .frame(width: 6, height: 6)
                    .shadow(color: PipeworkTheme.primaryCyan, radius: 4)

                Text("PIPEWORK")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(2.0)
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: toggleSound) {
                    Image(systemName: persistence.profile.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(persistence.profile.soundEnabled ? PipeworkTheme.textMain : PipeworkTheme.textDim)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(PipeworkTheme.panelBase))
                }

                Button(action: {
                    HapticService.shared.buttonTap()
                    isSettingsOpen = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(PipeworkTheme.panelBase))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Tactical Controls Zone

    private var controlsZone: some View {
        HStack(spacing: 28) {
            // Undo Button
            tacticalRoundButton(
                iconName: "arrow.uturn.backward",
                label: "Undo",
                disabled: !history.canUndo || isVictoryPresented,
                action: undoAction
            )

            // Hint Button
            tacticalRoundButton(
                iconName: "lightbulb",
                label: "Hint",
                disabled: isVictoryPresented,
                action: provideHintAction
            )

            // Restart Button
            tacticalRoundButton(
                iconName: "arrow.triangle.2.circlepath",
                label: "Restart",
                disabled: false,
                action: restartLevelAction
            )
        }
    }

    private func tacticalRoundButton(
        iconName: String,
        label: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
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
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(disabled ? PipeworkTheme.textDim : Color(red: 140/255, green: 160/255, blue: 180/255))
            }
        }
        .disabled(disabled)
        .buttonStyle(TactileButtonStyle())
    }

    // MARK: - Stroke & Victory Coordination

    private func handleStrokeCommitted(_ result: StrokeCommitResult) {
        if result.isPuzzleSolved {
            persistence.recordLevelCompletion(
                levelId: currentLevel.id,
                moves: puzzleState.moveCount,
                parMoves: currentLevel.parMoves
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(duration: 0.4)) {
                    isVictoryPresented = true
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleSound() {
        let newSound = !persistence.profile.soundEnabled
        persistence.updateSettings(sound: newSound)
        HapticService.shared.buttonTap()
    }

    private func undoAction() {
        if let previous = history.undo(currentState: puzzleState) {
            puzzleState = previous
            AudioService.shared.playUndo()
            HapticService.shared.undo()
        }
    }

    private func provideHintAction() {
        guard !puzzleState.isSolved else { return }

        guard let canonical = currentLevel.canonicalSolution else {
            showToast("Hint unavailable")
            return
        }

        var targetDef: CanonicalPathDefinition? = nil
        for pathDef in canonical {
            let currentPath = puzzleState.paths[pathDef.lineId]
            if currentPath == nil || currentPath?.coordinates != pathDef.path {
                targetDef = pathDef
                break
            }
        }

        guard let target = targetDef else { return }

        // Start transaction for hint
        history.beginTransaction(with: puzzleState)

        // Clear conflicting lines
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
            _ = history.commitTransaction(with: puzzleState)
            puzzleState.moveCount += 1

            AudioService.shared.playConnectionLocked()
            HapticService.shared.lineConnected()
            showToast("Hint revealed")

            if puzzleState.isSolved {
                HapticService.shared.boardCompleted()
                AudioService.shared.playPressureStabilized()
                handleStrokeCommitted(StrokeCommitResult(didMutate: true, didConnectLine: true, moveCountIncremented: true, isPuzzleSolved: true))
            }
        }
    }

    private func restartLevelAction() {
        puzzleState = currentLevel.createInitialState()
        history.clear()
        isVictoryPresented = false
        AudioService.shared.playRestart()
        HapticService.shared.restart()
        showToast("Level reset")
    }

    private func loadNextLevel() {
        HapticService.shared.buttonTap()
        let allPacks = LevelRepository.allPacks
        let currentPackIdx = allPacks.firstIndex(where: { $0.id == currentPack.id }) ?? 0
        let currentLevelIdx = currentPack.levels.firstIndex(where: { $0.id == currentLevel.id }) ?? 0

        if currentLevelIdx + 1 < currentPack.levels.count {
            let nextLevel = currentPack.levels[currentLevelIdx + 1]
            withAnimation(.easeInOut(duration: 0.3)) {
                currentLevel = nextLevel
                puzzleState = nextLevel.createInitialState()
                history.clear()
                isVictoryPresented = false
            }
        } else if currentPackIdx + 1 < allPacks.count {
            let nextPack = allPacks[currentPackIdx + 1]
            let nextLevel = nextPack.levels[0]
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPack = nextPack
                currentLevel = nextLevel
                puzzleState = nextLevel.createInitialState()
                history.clear()
                isVictoryPresented = false
            }
        } else {
            onOpenLevelSelect()
        }
    }

    private func showToast(_ text: String) {
        toastWorkItem?.cancel()
        withAnimation(.easeIn(duration: 0.15)) {
            toastMessage = text
        }
        let work = DispatchWorkItem {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.25)) {
                    toastMessage = nil
                }
            }
        }
        toastWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }
}

private struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
