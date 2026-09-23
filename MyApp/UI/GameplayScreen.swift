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

                // 3. Hero Board Container
                BoardCanvasView(
                    state: $puzzleState,
                    history: $history,
                    showAccessibilitySymbols: persistence.profile.accessibilitySymbolsEnabled,
                    reduceMotion: persistence.profile.reduceMotionEnabled,
                    onStrokeCommitted: handleStrokeCommitted
                )
                .aspectRatio(1.0, contentMode: .fit)
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity)

                // Feedback owns a stable lane so it never competes with the controls.
                ZStack {
                    if let toast = toastMessage {
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
                            .transition(.opacity)
                    }
                }
                .frame(height: 28)

                // 4. Bottom Tactical Controls Zone (Undo, Hint, Restart)
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
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(PipeworkTheme.textMain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 24/255, green: 31/255, blue: 39/255), PipeworkTheme.panelBase],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PipeworkTheme.borderBright.opacity(0.7), lineWidth: 1))
                )
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(PipeworkTheme.primaryCyan)
                    .frame(width: 6, height: 6)
                    .shadow(color: PipeworkTheme.primaryCyan, radius: 4)

                Text("PIPEWORK")
                    .font(PipeworkTheme.monoFont(size: 16, weight: .semibold))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(3.1)
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: toggleSound) {
                    Image(systemName: persistence.profile.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(persistence.profile.soundEnabled ? PipeworkTheme.textMain : PipeworkTheme.textDim)
                        .frame(width: 32, height: 32)
                        .background(headerControlBackground)
                }

                Button(action: {
                    HapticService.shared.buttonTap()
                    isSettingsOpen = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(headerControlBackground)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var headerControlBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color(red: 24/255, green: 31/255, blue: 39/255), Color(red: 10/255, green: 14/255, blue: 18/255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(PipeworkTheme.borderBright.opacity(0.65), lineWidth: 1))
            .shadow(color: .black.opacity(0.42), radius: 4, y: 2)
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
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 32/255, green: 42/255, blue: 52/255), Color(red: 10/255, green: 14/255, blue: 19/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(Color.black.opacity(0.85), lineWidth: 3))
                        .overlay(Circle().stroke(disabled ? PipeworkTheme.borderDim : PipeworkTheme.primaryCyan.opacity(0.48), lineWidth: 1))
                        .shadow(color: disabled ? .clear : PipeworkTheme.primaryCyan.opacity(0.12), radius: 7)
                        .shadow(color: Color.black.opacity(0.72), radius: 7, y: 4)

                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: 42, height: 42)

                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(disabled ? PipeworkTheme.textDim : Color(red: 166/255, green: 191/255, blue: 205/255))
                }

                Text(label.uppercased())
                    .font(PipeworkTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(disabled ? PipeworkTheme.textDim : PipeworkTheme.textMuted)
                    .tracking(1.25)
            }
        }
        .disabled(disabled)
        .buttonStyle(TactileButtonStyle())
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
                withAnimation(.spring(duration: 0.4)) {
                    isVictoryPresented = true
                }
            }
        } else if result.didMutate,
                  puzzleState.connectedLineCount == puzzleState.totalLineCount,
                  puzzleState.pressurePercentage < 100,
                  !hasShownPressureGuidance {
            hasShownPressureGuidance = true
            showToast("LINES COMPLETE · PRESSURE \(puzzleState.pressurePercentage)% · FILL EVERY CELL")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    private func showOnboardingPromptIfNeeded() {
        guard currentLevel.packId == LevelRepository.sector5x5Pack.id else { return }
        switch currentLevel.number {
        case 1:
            showToast("CONNECT MATCHING TERMINALS")
        case 2:
            showToast("FILL EVERY CELL · PRESSURE MUST REACH 100%")
        case 4:
            showToast("DRAG THROUGH A ROUTE TO CUT IT")
        default:
            break
        }
    }
}

private struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
