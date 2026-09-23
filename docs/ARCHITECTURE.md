# PIPEWORK — Architecture Specification

## 1. Architectural Philosophy
PIPEWORK is designed with strict separation between **Pure Puzzle Engine**, **State/Session Management**, **High-Performance Rendering**, and **UI Chrome / Navigation**.

```
┌─────────────────────────────────────────────────────────────┐
│                       SwiftUI Shell                         │
│   (App, MainMenu, SectorBrowser, SettingsView, HUD, Modal)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ User Actions & Bindings
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   GameSessionViewModel                      │
│        - Level state & progression                          │
│        - Timer & move history tracking                      │
│        - Audio / Haptic service invocations                 │
└──────────────┬──────────────────────────────┬───────────────┘
               │ Gesture Events               │ Immutable State Updates
               ▼                              ▼
┌──────────────────────────────┐     ┌────────────────────────┐
│    GridGestureInterpreter    │     │   Pure Swift Engine    │
│ - Touch position to GridCell │     │ - Grid & GridCoord     │
│ - Orthogonal Raycasting      │     │ - PipePath & Terminal  │
│ - Bresenham cell stepping    │     │ - PuzzleState & Rules  │
└──────────────────────────────┘     │ - MoveHistorySnapshot  │
                                     └────────────────────────┘
```

---

## 2. Directory & Module Structure

```
MyApp/
├── App/
│   ├── PIPEWORKApp.swift              # Main entry point & App lifecycle
│   ├── AppEnvironment.swift           # Central dependency container
│   └── NavigationCoordinator.swift    # App navigation router
├── Engine/                            # PURE SWIFT (No UIKit/SwiftUI/CoreGraphics)
│   ├── GridCoord.swift                # (x, y) coordinate struct & math
│   ├── GridDirection.swift            # North, South, East, West enum
│   ├── GridSize.swift                 # Width x Height & bounds checking
│   ├── FluidType.swift                # Fluid identifier, name, styling token
│   ├── Terminal.swift                 # Endpoint socket descriptor
│   ├── PipePath.swift                 # Ordered list of coordinates for a line
│   ├── PuzzleState.swift              # Authoritative immutable/mutable state
│   ├── PuzzleRules.swift              # Rule evaluator, win validator, pressure
│   └── MoveHistory.swift              # Undo/Redo snapshot manager
├── Levels/
│   ├── LevelDefinition.swift          # Codable puzzle model (Level ID, size, terminals)
│   ├── LevelPack.swift                # Collection of levels (Sector 5x5, 6x6, etc.)
│   ├── LevelRepository.swift          # Bundle level loader & repository
│   └── ProgressionManager.swift       # Completed levels, stars, best scores
├── Rendering/
│   ├── BoardGeometry.swift            # Coordinate mapping (Screen Point <-> GridCoord)
│   ├── BoardCanvasView.swift          # SwiftUI Canvas high-performance board renderer
│   ├── TerminalRenderer.swift         # Mechanical collar & LED rendering
│   ├── PipeRenderer.swift             # Thick rounded pipe segments & glowing cores
│   └── FluidPulseAnimator.swift       # Fluid flow pulse phase driver
├── Interaction/
│   ├── GridGestureInterpreter.swift   # Drag interpolation & cell stepping
│   └── TouchFeedbackController.swift  # Haptic & audio trigger coordination
├── Solver/
│   ├── PuzzleSolver.swift             # Constraint-satisfaction backtracking solver
│   ├── IslandDetector.swift           # Unreachable empty pocket pruning
│   └── SolutionValidator.swift        # Uniqueness & 100% coverage verifier
├── Generation/
│   ├── PuzzleGenerator.swift          # Solution-first partition generator
│   ├── Canonicalizer.swift            # Board transformation normalizer (D4 symmetry)
│   └── DifficultyAnalyzer.swift       # Path complexity & branch factor scoring
├── Services/
│   ├── HapticService.swift            # UIImpactFeedbackGenerator wrapper
│   ├── AudioService.swift             # AVAudioPlayer synthetic procedural sounds
│   └── PersistenceService.swift       # JSON/UserDefaults storage with migration
└── UI/
    ├── DesignSystem/                  # Design tokens (Colors, Typography, Spacing)
    │   ├── Colors.swift               # Graphite, Cyan, Amber, Emerald, Ruby, etc.
    │   ├── Typography.swift           # Industrial mono/technical fonts
    │   └── LayoutMetrics.swift        # Corner radii, pipe stroke widths
    ├── Components/                    # Reusable widgets
    │   ├── IndustrialButton.swift     # Beveled tactical button
    │   ├── GaugeView.swift            # Pressure progress gauge
    │   └── StatusPanel.swift          # Lines, Moves, Pressure HUD panel
    └── Screens/
        ├── BlipmadeSplashView.swift   # Minimal restrained studio intro
        ├── MainMenuView.swift         # Tactical title screen
        ├── SectorSelectView.swift     # Pack & level grid browser
        ├── GameplayScreen.swift       # Main puzzle screen & controls
        ├── VictoryOverlayView.swift   # Level completion modal
        └── SettingsScreen.swift       # Audio, haptics, colorblind options
```

---

## 3. Data Flow & State Mutation Rules
1. **Unidirectional Data Flow**:
   - `Touch Input` $\to$ `GridGestureInterpreter` $\to$ `PuzzleState.applyAction(...)` $\to$ `@Observable GameSession` $\to$ `SwiftUI View / Canvas`.
2. **Deterministic Engine**:
   - Given a `PuzzleState` and an input `PuzzleAction(stepTo: GridCoord)`, the new `PuzzleState` is computed purely and synchronously.
3. **Rendering Isolation**:
   - `BoardCanvasView` uses SwiftUI `Canvas` (GraphicsContext) to draw background grid cells, active pipes, terminal collars, and completion pulses in a single pass without child view overhead.
