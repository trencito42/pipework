# PIPEWORK — Agent Guide & Architecture Source of Truth

> **Read this file before modifying the project.**

This repository contains the native iOS implementation of **PIPEWORK**, an industrial fluid-routing connection puzzle game created by **Blipmade**.

---

## 1. What PIPEWORK Is
PIPEWORK is a premium native iPhone connection puzzle game set within an industrial fluid-routing fiction. The player repairs fluid grids by connecting pairs of matching pipe terminals (coolant, fuel, chemical, pressure, thermal, auxiliary) with non-overlapping, orthogonal paths that achieve **100% board coverage (100% PRESSURE)**.

---

## 2. Core Gameplay Rules
1. **Grid**: A square grid ($N \times N$, from $5 \times 5$ up to $12 \times 12$).
2. **Terminals**: Color-coded endpoints representing industrial fluid lines. Each pair has exactly 2 terminals.
3. **Orthogonal Routing**: Paths move only North, South, East, and West (no diagonal movement).
4. **No Crossing / No Sharing**: Paths cannot cross each other or occupy the same cell.
5. **No Branching**: Paths are strictly single continuous chains with two endpoints.
6. **Auto Cut (Collision Handling)**: Dragging an active pipe route through a cell occupied by another line automatically cuts the conflicting line at that cell, leaving the remainder intact.
7. **Backtracking**: Dragging backwards over the currently active path erases path segments naturally.
8. **Win Condition**:
   $$\text{Connected Pairs} == \text{Total Pairs} \quad \text{AND} \quad \text{Occupied Usable Cells} == \text{Total Usable Cells (100\% Coverage)}$$
   The UI represents full coverage as **PRESSURE 100%**. Connecting all pairs without 100% coverage does **not** solve the level.

---

## 3. Architecture Overview
PIPEWORK strictly separates puzzle logic, UI state, rendering, and persistence:

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                        │
│   (MainMenu, LevelSelect, GameScreen, HUD, Overlays)    │
└────────────────────────────┬────────────────────────────┘
                             │ Observes & Sends Actions
                             ▼
┌─────────────────────────────────────────────────────────┐
│                 GameSessionViewModel                    │
│   (Manages active level, timer, move counter, undo)     │
└──────────────┬────────────────────────────┬─────────────┘
               │ Gesture Events             │ Engine Mutations
               ▼                            ▼
┌──────────────────────────────┐   ┌──────────────────────┐
│   GridGestureInterpreter     │   │   Pure Swift Engine  │
│ (Cell hit-testing & raycast) │   │ (PuzzleState, Grid,  │
└──────────────────────────────┘   │  PipePath, Rules)    │
                                   └──────────────────────┘
```

- **`Engine/`**: Pure Swift puzzle data structures and rules. **Zero dependencies on SwiftUI/UIKit**. Fast, deterministic, and 100% unit-tested.
- **`Levels/`**: Codable level definitions, packs, and bundled level repository.
- **`Rendering/`**: High-performance SwiftUI `Canvas` & CoreGraphics drawing components. Event-driven redraws with zero continuous timer polling.
- **`Interaction/`**: Grid touch interpolation, gesture smoothing, and auto-cut routing.
- **`Solver/`**: Deterministic backtracking solver with MRV, constraint propagation, and unreachable island pruning.
- **`Generation/`**: Offline/tooling solution-first level generator, canonicalizer, and difficulty analyzer.
- **`Services/`**: Haptics (`UIImpactFeedbackGenerator`), Audio (`AVAudioPlayer` / AudioToolbox), and Persistence (`UserDefaults` / JSON File storage with schema migration).

---

## 4. Where Level Data Lives
- Shipped level data is packaged in JSON format under `Resources/Levels/` or compiled into `LevelRepository.swift`.
- Level definitions conform to `Codable` and use stable identifiers (`packID`, `levelNumber`, `size`).
- Every level format adheres to `docs/LEVEL_FORMAT.md`.

---

## 5. Puzzle Validation
- Puzzles are **solution-first**: a complete board partition is constructed first, then endpoints are extracted, andintermediate path cells are hidden.
- Puzzles are verified using the deterministic solver (`docs/SOLVER.md`) to guarantee:
  1. Solvability with 100% board coverage.
  2. Exactly one unique solution (or known acceptable branching for specific designer packs).
  3. No isolated empty dead-ends or unfillable pockets.

---

## 6. Mandatory Reading Before Modifying Code
Before touching specific subsystems, agents must read the relevant document:

| Area | Required Document |
|---|---|
| Gameplay logic, auto-cut, touch interpolation | `docs/GAMEPLAY.md` |
| Code layout, types, state management | `docs/ARCHITECTURE.md` |
| Level schema, serialization, packs | `docs/LEVEL_FORMAT.md` |
| Level generator algorithm | `docs/LEVEL_GENERATION.md` |
| Solver & constraint pruning | `docs/SOLVER.md` |
| UI design tokens, colors, typography, layout | `docs/IOS_DESIGN_SYSTEM.md` |
| Haptics & sound guidelines | `docs/AUDIO_HAPTICS.md` |
| Progress storage, save versioning | `docs/PERSISTENCE.md` |
| Accessibility & colorblind modes | `docs/ACCESSIBILITY.md` |
| Architectural decisions log | `docs/DECISIONS.md` |
| Testing guidelines & suites | `docs/TESTING.md` |

---

## 7. Coding Conventions
- **Language**: Swift 6 / Modern Swift with structured concurrency.
- **Frameworks**: SwiftUI for navigation, HUD, chrome; SwiftUI `Canvas` / Core Graphics for grid rendering. No WebViews.
- **Indentation**: 4 spaces.
- **Naming**: PascalCase for types/protocols, camelCase for properties/functions.
- **State**: Single source of truth. Use `@Observable` / `@State` / `@Binding`. No duplicated transient puzzle state.
- **Safety**: No force unwrapping (`!`) in production code; handle optionals safely with `guard` / `if let`.
- **Performance**: Redraw only on state changes. Never run an unbounded timer at 60/120Hz unless actively driving fluid pulse animations.

---

## 8. UI & Design Constraints
- **Aesthetic**: Minimalist industrial fluid-routing console. Near-black graphite surfaces, subtle borders, restrained cyan accents, vivid fluid tubes with glowing core paths, mechanical terminal collars.
- **Safe Areas**: Strict adherence to Dynamic Island, Home Indicator, and device safe area insets.
- **Square Boards**: The puzzle board is strictly square, centered with dynamic sizing based on `GeometryReader`. Cells must never stretch.
- **Theme**: Do not use cartoon plumbing, neon rainbow explosions, or generic SaaS card gradients.

---

## 9. Immutable Rules (Never Change Casually)
1. **100% Board Coverage**: Win condition strictly requires $100\%$ occupied usable cells. Never relax this rule.
2. **Pure Swift Engine Isolation**: `PuzzleState` and `PuzzleRules` must never import SwiftUI, UIKit, or CoreGraphics.
3. **Deterministic Daily Puzzles**: Daily puzzle generation/lookup must remain deterministic for a given calendar date.
4. **Solution-First Content**: Never generate puzzles by placing random endpoints and hoping they connect to 100%.

---

## 10. Documenting Architectural Changes
Whenever introducing a significant architectural decision or altering engine behavior:
1. Append an entry to `docs/DECISIONS.md` with rationale and alternatives considered.
2. Update `docs/CHANGELOG.md`.
3. If concluding a multi-step task, create a handoff report in `docs/agent-handoffs/YYYY-MM-DD-topic.md`.
