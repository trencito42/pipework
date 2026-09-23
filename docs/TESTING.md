# PIPEWORK — Testing & Quality Assurance Specification

## 1. Test Architecture
PIPEWORK utilizes Apple's modern **Testing** framework (`import Testing`) for all unit and integration tests, ensuring rapid execution and deterministic verification.

---

## 2. Core Test Suites

### Suite 1: Pure Engine Unit Tests (`EngineTests.swift`)
- **Coordinate Math**: Bounds validation, Manhattan distance, adjacent neighbors.
- **Orthogonal Movement**: Disallow diagonal steps, invalid non-adjacent skips.
- **Path Backtracking**: Pop leading cells when moving backwards; deep redraw trimming.
- **Auto-Cut Collision Handling**:
  - Cutting an intermediate segment of another line truncates the victim line and frees subsequent cells.
  - Attempting to draw over an enemy terminal is rejected.
- **Coverage & Pressure Calculation**:
  - Accurate counting of occupied usable cells.
  - Proper integer and floating-point pressure percentage calculation.
- **Win Condition Verification**:
  - All pairs connected + 100% coverage $\implies$ Solved.
  - All pairs connected + $< 100\%$ coverage $\implies$ NOT solved.
  - Partial connections + 100% coverage (impossible theoretically, but tested) $\implies$ NOT solved.
- **Move History & Undo/Restart**:
  - Undo restores exact previous state (geometry, line status, pressure).
  - Restart resets board to pristine condition.

### Suite 2: Level Format & Repository Tests (`LevelTests.swift`)
- JSON decoding and encoding fidelity for `LevelDefinition`.
- Every bundled level must have valid terminal pairs, no out-of-bounds coordinates, and non-empty IDs.

### Suite 3: Solver & Validator Tests (`SolverTests.swift`)
- Solves known $5 \times 5$, $6 \times 6$, and $7 \times 7$ puzzles.
- Correctly identifies unsolvable / impossible puzzles with isolated unfillable voids.
- Proves solution uniqueness for canonical pack levels.
