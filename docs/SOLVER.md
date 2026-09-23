# PIPEWORK — Solver & Constraint Pruning Specification

## 1. Solver Purpose
The solver serves three primary roles:
1. **Offline Level Validation**: Proving that generated/authored levels have at least one valid full-coverage solution.
2. **Uniqueness Verification**: Ensuring puzzle has exactly 1 unique solution.
3. **Runtime Hint System**: Calculating the forced next move or route for a player upon request without brute force stalling.

---

## 2. Solver Algorithm
The solver treats the puzzle as a **Constraint Satisfaction Problem (CSP)** with depth-first backtracking search and forward checking.

### Key Pruning Rules
1. **Corner Degree Constraint**:
   - Corner cells have only 2 orthogonal neighbors.
   - If an empty corner cell is not an endpoint, it must be traversed by a single path using both its available neighbors (degree = 2).
   - If a corner cell is an endpoint, it has degree = 1.
   - If available neighbors fall below required degree, the branch is **pruned immediately**.
2. **Edge Degree Constraint**:
   - Non-endpoint boundary cells have 3 neighbors; if 2 neighbors are blocked, the remaining 2 are forced.
3. **Dead-End / Isolated Void Pruning (Flood Fill Island Detection)**:
   - Run connected-component analysis on all unassigned board cells.
   - If any connected component of unassigned cells contains **no endpoints**, it can never be filled by any path entering and leaving without crossing $\implies$ **Prune immediately**.
   - If a connected component contains only 1 endpoint, it cannot be exited $\implies$ **Prune immediately**.
4. **Endpoint Reachability**:
   - If terminal $A$ cannot reach matching terminal $B$ through available unassigned cells (via BFS), the branch is **pruned immediately**.

---

## 3. Solver Complexity & Runtime Budget
- For $5 \times 5$ to $8 \times 8$, with degree constraints and island pruning, solutions are resolved in $< 5\text{ ms}$.
- For larger boards ($9 \times 9$ to $12 \times 12$), search space pruning eliminates $> 99.8\%$ of branches within $50\text{ ms}$.
