# PIPEWORK — Solution-First Level Generation Specification

## 1. Core Generation Pipeline
PIPEWORK adheres to a strict **Solution-First** generation paradigm:

```
[1. INITIAL FULL PARTITION]
Randomized spanning snake/tree decomposition of N x N board into K continuous non-intersecting chains
                    ↓
[2. CELL COVERAGE VALIDATION]
Verify exact 100% cell assignment (sum of path lengths == N * N)
                    ↓
[3. TERMINAL EXTRACTION]
Extract path start and end coordinates as terminal sockets; discard all intermediate points
                    ↓
[4. SOLVER CONSTRAINTS & UNIQUENESS TEST]
Execute backtracking solver to count all valid 100%-coverage solutions
                    ↓
[5. QUALITY & DIFFICULTY FILTER]
Reject trivial puzzles (straight parallel lines), ensure minimum snake/bend density
                    ↓
[6. CANONICAL D4 SIGNATURE]
Compute invariant canonical hash under 8 symmetries to reject duplicates
                    ↓
[7. EXPORT TO LEVEL DEFINITION]
Pack into LevelDefinition JSON with pre-verified canonical solution
```

---

## 2. Partition Algorithms
1. **Hamiltonian / Spanning Tree Subdivision**:
   - Start with full grid partition (e.g. Kruskal's/Wilson's algorithm or random walk filling).
   - Merge/split branches into $K$ disjoint chains of length $\ge 3$.
2. **Snake Growth with Wall Adherence**:
   - Grow $K$ seeds simultaneously in random orthogonal directions until entire board is saturated.
   - If any unfillable $1 \times 1$ dead-end void appears, backtrack seed growth immediately.

---

## 3. Quality Heuristics
A generated puzzle is accepted only if:
- **Pair Count $K$**: Between $\lfloor N \times 0.8 \rfloor$ and $N + 1$.
- **Average Path Length**: $\ge N \times 1.2$.
- **Turns / Bends**: Each path must contain at least 1–2 direction changes (no puzzles consisting purely of straight bars).
- **Unique Solution Count**: Solver returns exactly 1 solution that achieves 100% coverage.

## 4. Logical Identity and Failure

Generated lines use stable logical IDs (`line_0`, `line_1`, …) independently of their visual `FluidType`; visual fluids cycle through all cases, including Steam. Production generation throws `GenerationError` after exhausting attempts instead of silently substituting an unrelated fallback level.

## 5. Campaign Canonicalization

`LevelTopology.d4CanonicalHash` normalizes terminal topology across all eight square symmetries, pair ordering, endpoint ordering, and fluid assignment. `LevelRepository` retains the first stable level ID in each equivalence class and removes later structural duplicates before exposing campaign content.
