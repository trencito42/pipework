import SwiftUI

/// Main native interactive gameplay screen for PIPEWORK.
public struct GameplayScreen: View {
    @ObservedObject private var persistence = PersistenceService.shared

    public let initialPack: LevelPack
    public let initialLevel: LevelDefinition
    public let isProceduralMode: Bool
    public let onExitToMenu: () -> Void
    public let onOpenSectorMatrix: () -> Void

    @State private var currentPack: LevelPack
    @State private var currentLevel: LevelDefinition
    @State private var puzzleState: PuzzleState
    @State private var history = MoveHistory()
    @State private var isVictoryPresented: Bool = false
    @State private var toastMessage: String? = nil
    @State private var toastWorkItem: DispatchWorkItem? = nil
    @State private var blockedCoord: GridCoord? = nil
    @State private var isSoundOn: Bool = true
    @State private var isSettingsOpen: Bool = false

    public init(
        pack: LevelPack = LevelRepository.sector7x7Pack,
        level: LevelDefinition = LevelRepository.sector7x7Pack.levels[0],
        isProceduralMode: Bool = false,
        onExitToMenu: @escaping () -> Void = {},
        onOpenSectorMatrix: @escaping () -> Void = {}
    ) {
        self.initialPack = pack
        self.initialLevel = level
        self.isProceduralMode = isProceduralMode
        self.onExitToMenu = onExitToMenu
        self.onOpenSectorMatrix = onOpenSectorMatrix

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
                        showAccessibilitySymbols: persistence.profile.accessibilitySymbolsEnabled,
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
                    sectorName: "\(currentPack.name) — Level \(currentLevel.number)",
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
                // Record persistence progress
                persistence.recordLevelCompletion(
                    levelId: currentLevel.id,
                    moves: puzzleState.moveCount,
                    parMoves: currentLevel.parMoves
                )

                withAnimation(.spring(duration: 0.4)) {
                    isVictoryPresented = true
                }
            }
        }
        .sheet(isPresented: $isSettingsOpen) {
            SettingsScreen()
        }
        .onAppear {
            isSoundOn = persistence.profile.soundEnabled
            AudioService.shared.isEnabled = isSoundOn
            HapticService.shared.isEnabled = persistence.profile.hapticsEnabled
        }
    }

    // MARK: - Header Zone

    private var headerZone: some View {
        HStack {
            // Exit / Sector Matrix button
            Button(action: onOpenSectorMatrix) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("SECTORS")
                        .font(PipeworkTheme.monoFont(size: 11, weight: .bold))
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

            // Brand Title with Status Dot
            HStack(spacing: 6) {
                Circle()
                    .fill(PipeworkTheme.primaryCyan)
                    .frame(width: 6, height: 6)
                    .shadow(color: PipeworkTheme.primaryCyan, radius: 4)

                Text("PIPEWORK")
                    .font(PipeworkTheme.roundedFont(size: 18, weight: .heavy))
                    .foregroundColor(PipeworkTheme.textMain)
                    .tracking(2.0)
            }

            Spacer()

            // Settings & Sound Buttons
            HStack(spacing: 6) {
                Button(action: toggleSound) {
                    Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSoundOn ? PipeworkTheme.textMain : PipeworkTheme.textDim)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 6).fill(PipeworkTheme.panelBase))
                }

                Button(action: { isSettingsOpen = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(PipeworkTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 6).fill(PipeworkTheme.panelBase))
                }
            }
        }
        .padding(.horizontal, 16)
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
        persistence.updateSettings(sound: isSoundOn)
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
        guard let canonical = currentLevel.canonicalSolution else {
            showToast("DIAGNOSTIC UNAVAILABLE")
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
        if isProceduralMode {
            // Generate next procedural puzzle
            let nextLevel = LevelGenerator.generateLevel(
                size: currentLevel.size,
                pairCount: currentLevel.pairs.count,
                packId: "procedural",
                levelNumber: currentLevel.number + 1
            )
            withAnimation(.easeInOut(duration: 0.3)) {
                currentLevel = nextLevel
                puzzleState = nextLevel.createInitialState()
                history.clear()
                isVictoryPresented = false
            }
            return
        }

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
            onOpenSectorMatrix()
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
