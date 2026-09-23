# PIPEWORK — Architectural Decision Records (ADRs)

## ADR-001: Native Swift & SwiftUI Application
- **Status**: Accepted
- **Context**: Need a responsive, high-framerate, premium native iOS experience without cross-platform web layers.
- **Decision**: Build purely in native Swift using SwiftUI for app structure/navigation and SwiftUI `Canvas` (with Core Graphics) for board rendering. No WebViews, no React Native, no third-party engines.

---

## ADR-002: Pure Swift Engine Isolation
- **Status**: Accepted
- **Context**: Puzzle logic must be 100% testable, fast, and reusable across UI, solver, and offline generator without UI dependencies.
- **Decision**: Keep all engine files (`GridCoord`, `PipePath`, `PuzzleState`, `PuzzleRules`) purely in Swift without importing `SwiftUI`, `UIKit`, or `CoreGraphics`.

---

## ADR-003: Solution-First Level Construction
- **Status**: Accepted
- **Context**: Placing random endpoints creates unsolvable levels or leaves arbitrary empty space that forces artificial snaking.
- **Decision**: All level generation and authoring begins with a complete, valid orthogonal board partition covering 100% of usable cells, extracting endpoints from the solved partition.

---

## ADR-004: Strict 100% Board Coverage (100% PRESSURE) Win Condition
- **Status**: Accepted
- **Context**: Casual connection games sometimes allow leaving empty dead cells.
- **Decision**: A level is strictly completed only when all pairs are connected AND every usable board cell is filled (100% PRESSURE).

---

## ADR-005: Auto-Cut Collision Resolution
- **Status**: Accepted
- **Context**: When a player draws an active line through an existing line, manual erasing creates friction.
- **Decision**: Truncate the victim line at the collision point automatically, assigning the collided cell to the active drawing stroke and leaving the victim's preceding root connected to its start terminal.

---

## ADR-006: SwiftUI Canvas Single-Pass Grid Rendering
- **Status**: Accepted
- **Context**: Complex nested view hierarchies for $12 \times 12$ grids (144 individual cell views) cause layout and gesture overhead.
- **Decision**: Render the entire grid, active paths, and terminals inside a single SwiftUI `Canvas` / `GraphicsContext` with immediate vector draw commands, providing 120Hz performance on ProMotion devices with minimal overhead.

---

## ADR-007: Core Haptics Subsystem with Sensory Rate Limiting & Deduplication
- **Status**: Accepted
- **Context**: Drawing fast routes can generate dozens of micro-step events per second. Continuous vibration causes hand numbness and sensory fatigue. Blocked boundaries could spam repeated clicks if the finger trembles against the edge.
- **Decision**: Implement `CHHapticEngine` transient AHAP patterns throttled to 28ms for forward/backward steps, coordinate-based deduplication for blocked boundaries in `TouchFeedbackController`, and graceful fallback to `UIImpactFeedbackGenerator`.

---

## ADR-008: Non-Destructive Stroke Lifecycle & Transaction Ordering
- **Status**: Accepted
- **Context**: Tapping or resting a finger on a terminal or line should not truncate paths or register as accidental moves. Victory evaluation must always include the completing stroke in persistence.
- **Decision**: Implement an explicit `StrokePhase` machine (`idle` -> `armed` -> `dragging`). Transactions are rolled back if movement is less than 25% cell dimension. Victory is evaluated strictly after committing the final transaction and incrementing the move count.

---

## ADR-009: Attempt-Based Mastery and Assisted Runs
- **Status**: Accepted
- **Context**: Restoring snapshot move counts on Undo and granting clean mastery after a full-route Hint made the score misleading.
- **Decision**: A committed board-changing stroke remains counted after Undo. Hints mark the run assisted and cap its run award at two stars. Completion persistence captures the previous best before writing so `NEW BEST` is truthful.

---

## ADR-010: Stable-ID D4 Campaign Deduplication
- **Status**: Accepted
- **Context**: The source catalog contained 25 rotational/reflection duplicates, including only four unique 7×7 topologies among 26 records.
- **Decision**: Canonicalize topology at repository load, retain the first stable ID, and omit later equivalents. This preserves existing completion identifiers without presenting repeated boards.
