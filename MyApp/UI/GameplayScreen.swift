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
    @State private var wasAssisted: Bool = false
    @State private var completionOutcome: CompletionOutcome? = nil
    @State private var hasShownPressureGuidance: Bool = false

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
            // Low-contrast deep obsidian backdrop
            PipeworkTheme.bgBase
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // 1. Unified Navigation Header Bar
                headerZone
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // 2. Minimalist Status Bar (Lines, Moves, Pressure Gauge)
                StatusPanel(
                    connectedLines: puzzleState.connectedLineCount,
                    totalLines: puzzleState.totalLineCount,
                    moves: puzzleState.moveCount,
                    pressurePercentage: puzzleState.pressurePercentage
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 4)

                // 3. Hero Puzzle Board Container
                BoardCanvasView(
                    state: $puzzleState,
                    history: $history,
                    showAccessibilitySymbols: persistence.profile.accessibilitySymbolsEnabled,
                    reduceMotion: persistence.profile.reduceMotionEnabled,
                    onStrokeCommitted: handleStrokeCommitted
                )
                .aspectRatio(1.0, contentMode: .fit)
                .padding(.horizontal, 16)

                // 4. Feedback / Toast Notification Lane
                ZStack {
                    if let toast = toastMessage {
                        Text(toast)
                            .font(PipeworkTheme.captionFont(size: 12, weight: .semibold))
                            .foregroundColor(PipeworkTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(PipeworkTheme.bgElevated)
                                    .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .frame(height: 28)

                Spacer(minLength: 4)

                // 5. Tactical Bottom Controls Bar (Undo, Hint, Restart)
                controlsZone
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Victory Modal
            if isVictoryPresented {
                VictoryOverlayView(
                    levelTitle: "Level \(currentLevel.number)",
                    moves: puzzleState.moveCount,
                    parMoves: currentLevel.parMoves,
                    outcome: completionOutcome,
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
        .onAppear {
            persistence.markLevelPlayed(currentLevel.id)
            showOnboardingPromptIfNeeded()
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
                        .font(PipeworkTheme.headingFont(size: 14, weight: .semibold))
                }
                .foregroundColor(PipeworkTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(PipeworkTheme.bgElevated)
                        .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
                )
            }

            Spacer()

            // Centered Level Info
            VStack(spacing: 1) {
                Text("Level \(currentLevel.number)")
                    .font(PipeworkTheme.headingFont(size: 16, weight: .bold))
                    .foregroundColor(PipeworkTheme.textMain)
                Text("\(currentPack.name) · Par \(currentLevel.parMoves)")
                    .font(PipeworkTheme.captionFont(size: 11, weight: .medium))
                    .foregroundColor(PipeworkTheme.textMuted)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: toggleSound) {
                    Image(systemName: persistence.profile.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(persistence.profile.soundEnabled ? PipeworkTheme.textMain : PipeworkTheme.textMuted)
                }
                .buttonStyle(PipeworkIconButtonStyle(size: 34))

                Button(action: {
                    HapticService.shared.buttonTap()
                    isSettingsOpen = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(PipeworkTheme.textSecondary)
                }
                .buttonStyle(PipeworkIconButtonStyle(size: 34))
            }
        }
    }

    // MARK: - Bottom Tactical Controls Zone

    private var controlsZone: some View {
        HStack(spacing: 16) {
            // Undo Action
            tacticalControlButton(
                iconName: "arrow.uturn.backward",
                label: "Undo",
                disabled: !history.canUndo || isVictoryPresented,
                action: undoAction
            )

            // Hint Action
            tacticalControlButton(
                iconName: "lightbulb",
                label: "Hint",
                disabled: isVictoryPresented,
                action: provideHintAction
            )

            // Restart Action
            tacticalControlButton(
                iconName: "arrow.triangle.2.circlepath",
                label: "Restart",
                disabled: false,
                action: restartLevelAction
            )
        }
    }

    private func tacticalControlButton(
        iconName: String,
        label: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(PipeworkTheme.headingFont(size: 14, weight: .semibold))
            }
            .foregroundColor(disabled ? PipeworkTheme.textDim : PipeworkTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(PipeworkTheme.bgElevated)
                    .overlay(Capsule().stroke(PipeworkTheme.borderSubtle, lineWidth: 1))
            )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1.0)
        .buttonStyle(TactileControlStyle())
    }

    // MARK: - Stroke & Victory Coordination

    private func handleStrokeCommitted(_ result: StrokeCommitResult) {
        if result.isPuzzleSolved {
            completionOutcome = persistence.recordLevelCompletion(
                levelId: currentLevel.id,
                moves: puzzleState.moveCount,
                parMoves: currentLevel.parMoves,
                assisted: wasAssisted
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isVictoryPresented = true
                }
            }
        } else if result.didMutate,
                  puzzleState.connectedLineCount == puzzleState.totalLineCount,
                  puzzleState.pressurePercentage < 100,
                  !hasShownPressureGuidance {
            hasShownPressureGuidance = true
            showToast("Lines connected · Fill every cell to reach 100% pressure")
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
            var restored = previous
            restored.moveCount = puzzleState.moveCount
            puzzleState = restored
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
        wasAssisted = true

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
        completionOutcome = nil
        wasAssisted = false
        hasShownPressureGuidance = false
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
                completionOutcome = nil
                wasAssisted = false
                hasShownPressureGuidance = false
            }
            persistence.markLevelPlayed(nextLevel.id)
        } else if currentPackIdx + 1 < allPacks.count {
            let nextPack = allPacks[currentPackIdx + 1]
            let nextLevel = nextPack.levels[0]
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPack = nextPack
                currentLevel = nextLevel
                puzzleState = nextLevel.createInitialState()
                history.clear()
                isVictoryPresented = false
                completionOutcome = nil
                wasAssisted = false
                hasShownPressureGuidance = false
            }
            persistence.markLevelPlayed(nextLevel.id)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: work)
    }

    private func showOnboardingPromptIfNeeded() {
        guard currentLevel.packId == LevelRepository.sector5x5Pack.id else { return }
        switch currentLevel.number {
        case 1:
            showToast("Connect matching colored terminals")
        case 2:
            showToast("Fill every cell · 100% pressure required")
        case 4:
            showToast("Drag through an active route to cut it")
        default:
            break
        }
    }
}

private struct TactileControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
