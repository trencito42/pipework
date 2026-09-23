# CHANGELOG

## [1.3.0] - Progression, Mastery & Content Integrity
### Completed
- Continue now resumes the unfinished last-played level or the next incomplete unlocked level.
- Added gentle sequential unlocking and ten-level subsectors with completion/star summaries.
- Added version-2 backward-compatible persistence fields for continuation, unlocking, and assisted bests.
- Undo now preserves attempt count; full-route Hint marks a run assisted and caps its run rating at two stars.
- Victory captures previous best before persistence and displays stars, par, assisted status, Perfect Routing, and truthful New Best feedback.
- Added pressure-insufficient guidance and contextual opening-level onboarding prompts.
- Added deterministic D4 topology hashing, content audit records, solver-node difficulty reports, and runtime removal of 25 duplicated structures.
- Generator now uses independent `line_N` identities, includes Steam, and throws on generation exhaustion.
- Removed the developer-specific absolute level-data path.
- Paused Canvas timeline updates while the board has no active animation.
- Added an executable Swift Testing target; 7 tests and the 229-assertion legacy harness pass.

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
- **Regression Harness**: Expanded the then-custom `EngineTests.swift` runner with interaction, solver, and level certification checks. It was not yet an Xcode test target at this release.

## [1.1.0] - PIPEWORK Recovery & Stabilization Pass
### Completed
- **Continuous 1-Finger Multi-Turn Routing**: Implemented 2D Amanatides & Woo DDA / boundary intersection algorithm in `ContinuousGridTraverser.swift`. Finger moves smoothly through any number of turns without needing to stop or lift finger.
- **Strict Orthogonal Raycasting**: Guaranteed zero diagonal grid transitions even when crossing corners or fast-swiping diagonally.
- **Hardware-Level Touch Tracking Surface**: Created `TouchTrackingView.swift` leveraging direct UIKit touches with 120Hz ProMotion coalesced touch delivery.
- **Move Counting & Transactions**: Refactored `MoveHistory.swift` with atomic transaction lifecycle.
- **Curated Levels & Solution-First Validation**: Implemented `LevelValidator.swift` and verified 100% full-board coverage, canonical solution continuity, and solvability across curated packs.
