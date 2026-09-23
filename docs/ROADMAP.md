# PIPEWORK — Development Roadmap

## Phase 0: Foundations & Source of Truth
- [x] Create project memory docs in `/docs/` and root `AGENTS.md`.
- [x] Normalize project naming from boilerplate to `PIPEWORK`.
- [x] Establish pure Swift engine architecture.

## Phase 1: Pure Swift Puzzle Engine
- [x] Implement coordinate, grid, fluid, terminal, path, and state models.
- [x] Implement orthogonal path drawing, auto-cut collision resolution, backtracking, and undo.
- [x] Implement win condition validator (100% PRESSURE + all lines connected).
- [x] Verify complete test coverage.

## Phase 2: Native Playable Board
- [x] Implement `BoardCanvasView` with high-performance single-pass rendering.
- [x] Implement `GridGestureInterpreter` with multi-cell touch raycasting and interpolation.
- [x] Ship initial certified $5 \times 5$, $6 \times 6$, and $7 \times 7$ sector levels.

## Phase 3: Visual Polish & Tactile Feedback
- [x] Industrial terminal sockets, chamfered cell frames, thick fluid lines with glowing cores.
- [x] Dynamic fluid pulse animation for completed lines, paused while idle and under Reduce Motion.
- [x] Core Haptics vocabulary with UIKit fallback and lightweight system-sound audio.
- [x] Level victory overlay with delayed presentation and performance summary.

## Phase 4: Product Shell & Progression
- [ ] Blipmade studio splash animation (< 1s, respects Reduce Motion).
- [x] Industrial main menu and subsector-based level browser.
- [x] Versioned persistence, continuation, sequential unlocking, best moves, assisted status, and stars.
- [x] Settings screen (Haptics, Audio, Accessibility symbols, Reduce Motion, Reset progress).

## Phase 5: Solver & Validation Tooling
- [x] Constraint satisfaction backtracking solver with pruning and explored-node metrics.
- [x] Executable Swift Testing target plus legacy interaction/content certification harness.

## Phase 6: Level Generator & Canonical Deduplication
- [x] Solution-first partition generator with unique logical line identities and explicit failure.
- [x] D4 symmetry canonical hashing and campaign deduplication.
- [x] Deterministic solver/geometry difficulty analyzer and content audit records.
- [ ] Replace the four remaining unique 7×7 seeds with a substantially larger curated unique pack.

## Phase 7: Additional Modes & Polish
- [ ] Deterministic Daily Diagnostic mode with calendar streak tracking.
- [ ] Emergency Overhaul (Time Trial) mode.
- [ ] Game Center achievement hooks.
