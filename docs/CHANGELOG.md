# CHANGELOG

## [1.2.0] - Core Interaction, Tactile Haptics & Victory Overhaul
### Completed
- **Non-Destructive Stroke Lifecycle**: Implemented explicit 3-phase state machine (`idle` -> `armed` -> `dragging`) in `GridGestureInterpreter.swift`. Tapping on empty cells, start terminals, or existing/completed line segments without exceeding the deadband threshold performs zero mutations and logs 0 moves.
- **Touch-End Final Position Processing**: Enhanced `TouchTrackingView.swift` and `GridGestureInterpreter.endStroke` to pass and process the exact final touch coordinates before committing, guaranteeing that quick flick gestures connecting endpoints lock reliably.
- **Explicit Touch Cancellation Support**: Added `onTouchCancelled` routing to rollback the in-flight history transaction snapshot with zero move penalties or phantom strokes upon system gesture interrupts or notifications.
- **Blocked Route Reconciliation**: Pipe drawing hitting obstacles (boundaries or enemy terminals) retains its logical head at the last valid cell, allowing the player to slide sideways or backward without lifting their finger.
- **Directional Hysteresis & Axis Intent**: Added axis intent tracking and corner tie-breaking in `ContinuousGridTraverser.swift` and `GridDirection.Axis`.
- **Core Haptics Engine (`CHHapticEngine`)**: Built full custom AHAP parameter curves in `HapticService.swift` with ~28ms micro-step throttling, coordinate deduplication in `TouchFeedbackController.swift`, and UIKit fallback.
- **Deterministic Victory Flow**: Structured stroke commit sequence (`commit` -> `moveCount += 1` -> `isSolved` -> `recordLevelCompletion`) ensuring the final stored move count is mathematically accurate. Added a 350ms celebration delay before modal presentation.
- **Tactile UI Haptics**: Added consistent tactile button haptics across `MainMenuScreen`, `SectorSelectScreen`, `GameplayScreen`, and `SettingsScreen`.
- **Automated Regression Suite**: Expanded `EngineTests.swift` to 254 test assertions covering all 22 interaction regression scenarios, solver checks, and strict certification across all 176 shipped levels.

## [1.1.0] - PIPEWORK Recovery & Stabilization Pass
### Completed
- **Continuous 1-Finger Multi-Turn Routing**: Implemented 2D Amanatides & Woo DDA / boundary intersection algorithm in `ContinuousGridTraverser.swift`. Finger moves smoothly through any number of turns without needing to stop or lift finger.
- **Strict Orthogonal Raycasting**: Guaranteed zero diagonal grid transitions even when crossing corners or fast-swiping diagonally.
- **Hardware-Level Touch Tracking Surface**: Created `TouchTrackingView.swift` leveraging direct UIKit touches with 120Hz ProMotion coalesced touch delivery.
- **Move Counting & Transactions**: Refactored `MoveHistory.swift` with atomic transaction lifecycle.
- **Curated Levels & Solution-First Validation**: Implemented `LevelValidator.swift` and verified 100% full-board coverage, canonical solution continuity, and solvability across curated packs.
