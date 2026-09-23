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
