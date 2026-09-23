# PIPEWORK — Development Roadmap

## Phase 0: Foundations & Source of Truth (Current)
- [x] Create project memory docs in `/docs/` and root `AGENTS.md`.
- [x] Normalize project naming from boilerplate to `PIPEWORK`.
- [x] Establish pure Swift engine architecture.

## Phase 1: Pure Swift Puzzle Engine
- [x] Implement coordinate, grid, fluid, terminal, path, and state models.
- [x] Implement orthogonal path drawing, auto-cut collision resolution, backtracking, and undo.
- [x] Implement win condition validator (100% PRESSURE + all lines connected).
- [x] Verify complete test coverage.

## Phase 2: Native Playable Board
- [ ] Implement `BoardCanvasView` with high-performance single-pass rendering.
- [ ] Implement `GridGestureInterpreter` with multi-cell touch raycasting and interpolation.
- [ ] Ship initial curated $5 \times 5$, $6 \times 6$, and $7 \times 7$ sector levels.

## Phase 3: Visual Polish & Tactile Feedback
- [ ] Industrial terminal sockets, chamfered cell frames, thick fluid lines with glowing cores.
- [ ] Dynamic fluid pulse shader/animation for completed lines.
- [ ] Audio synthesis and native haptic feedback integration.
- [ ] Level victory overlay with pressure surge animation.

## Phase 4: Product Shell & Progression
- [ ] Blipmade studio splash animation (< 1s, respects Reduce Motion).
- [ ] Industrial main menu & tactical Sector Browser.
- [ ] Persistence manager with save/load, stats, and star rating.
- [ ] Settings screen (Haptics, Audio, Accessibility symbols, Reset progress).

## Phase 5: Solver & Validation Tooling
- [ ] Constraint satisfaction backtracking solver with island pruning.
- [ ] Offline test suite validating all shipping levels for 100% coverage and uniqueness.

## Phase 6: Level Generator & Canonical Deduplication
- [ ] Solution-first partition generator.
- [ ] D4 symmetry canonical hashing for level deduplication.
- [ ] Automated difficulty complexity analyzer.

## Phase 7: Additional Modes & Polish
- [ ] Deterministic Daily Diagnostic mode with calendar streak tracking.
- [ ] Emergency Overhaul (Time Trial) mode.
- [ ] Game Center achievement hooks.
