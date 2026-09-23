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
│                    GameSessionViewModel                     │
│        - Level state & progression                          │
│        - Timer & move history tracking                      │
│        - Audio / Haptic service invocations                 │
└──────────────┬──────────────────────────────┬───────────────┘
               │ Gesture Events               │ Immutable State Updates
               ▼                              ▼
┌──────────────────────────────┐     ┌────────────────────────┐
│    GridGestureInterpreter    │     │   Pure Swift Engine    │
│ - StrokePhase (Idle/Armed/   │     │ - Grid & GridCoord     │
│   Dragging)                  │     │ - PipePath & Terminal  │
│ - Continuous DDA Raycasting  │     │ - PuzzleState & Rules  │
│ - Hysteresis & Axis Intent   │     │ - MoveHistorySnapshot  │
│ - Feedback Coordination      │     └────────────────────────┘
└──────────────────────────────┘
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
│   ├── GridDirection.swift            # North, South, East, West enum & Axis enum
│   ├── GridSize.swift                 # Width x Height & bounds checking
│   ├── FluidType.swift                # Fluid identifier, name, styling token
│   ├── Terminal.swift                 # Endpoint socket descriptor
│   ├── PipePath.swift                 # Ordered list of coordinates for a line
│   ├── PuzzleState.swift              # Authoritative immutable/mutable state
│   ├── PuzzleRules.swift              # Rule evaluator, win validator, pressure
│   └── MoveHistory.swift              # Undo/Redo & atomic transaction manager
├── Levels/
│   ├── LevelDefinition.swift          # Codable puzzle model (Level ID, size, terminals)
│   ├── LevelPack.swift                # Collection of levels (Sector 5x5, 6x6, 7x7)
│   ├── LevelRepository.swift          # Bundle level loader & repository (176 certified levels)
│   ├── LevelValidator.swift           # Solver A / Solver B dual solvability certifier
│   └── LevelQualityScorer.swift       # Aesthetic and inflection metric scorer
├── Rendering/
│   ├── BoardGeometry.swift            # Coordinate mapping (Screen Point <-> GridCoord)
│   ├── BoardCanvasView.swift          # SwiftUI Canvas high-performance board renderer
│   ├── TerminalRenderer.swift         # Mechanical collar & LED rendering
│   ├── PipeRenderer.swift             # Thick rounded pipe segments & glowing cores
│   └── FluidPulseAnimator.swift       # Fluid flow pulse phase driver
├── Interaction/
│   ├── ContinuousGridTraverser.swift  # 2D DDA raycaster, axis intent & hysteresis
│   ├── GridGestureInterpreter.swift   # Non-destructive stroke lifecycle & step engine
│   ├── TouchFeedbackController.swift  # Haptic & audio trigger coordination with deduplication
│   └── TouchTrackingView.swift        # UIKit touch surface with 120Hz ProMotion support
├── Solver/
│   └── PuzzleSolver.swift             # Constraint-satisfaction backtracking solver
├── Generator/
│   └── LevelGenerator.swift           # Solution-first partition generator
├── Services/
│   ├── HapticService.swift            # Core Haptics engine with rate limiting & UIKit fallback
│   ├── AudioService.swift             # Lightweight procedural audio triggers
│   └── PersistenceService.swift       # JSON/UserDefaults profile & progress storage
└── UI/
    ├── DesignSystem/                  # Design tokens (Colors, Typography, LayoutMetrics)
    ├── Components/                    # Reusable tactile buttons, gauges, and HUD panels
    └── Screens/                       # MainMenu, SectorSelect, GameplayScreen, SettingsScreen
```

---

## 3. Data Flow & State Mutation Rules
1. **Unidirectional Data Flow**:
   - `TouchTrackingView` $\to$ `GridGestureInterpreter` $\to$ `PuzzleState` mutations $\to$ `BoardCanvasView` redraw.
2. **Stroke Phase Machine**:
   - `idle`: No active touch.
   - `armed`: Finger is down on a terminal or pipe segment. History transaction begun. Zero board changes made.
   - `dragging`: Finger moved beyond deadband. Path drawn, extended, backtracked, or severed. Logical head tracks last valid coordinate.
3. **Commit & Rollback**:
   - Touch lift with $< 25\%$ cell movement rolls back transaction (0 moves, 0 mutations).
   - Touch cancellation (system gesture / notification interruption) restores board snapshot immediately.
   - Touch completion commits transaction, increments `moveCount` by 1, and verifies win condition.
